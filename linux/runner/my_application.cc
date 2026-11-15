#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  GtkWindow* window;
  FlMethodChannel* open_files_channel;
  // Files opened before Dart asked for them; nullptr once it has.
  GPtrArray* pending_paths;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Answers Dart's "ready" with the files opened before it was listening.
static void open_files_method_call_cb(FlMethodChannel* channel,
                                      FlMethodCall* method_call,
                                      gpointer user_data) {
  MyApplication* self = MY_APPLICATION(user_data);
  if (g_strcmp0(fl_method_call_get_name(method_call), "ready") != 0) {
    fl_method_call_respond_not_implemented(method_call, nullptr);
    return;
  }
  g_autoptr(FlValue) paths = fl_value_new_list();
  if (self->pending_paths != nullptr) {
    for (guint i = 0; i < self->pending_paths->len; i++) {
      fl_value_append_take(
          paths, fl_value_new_string(static_cast<const gchar*>(
                     g_ptr_array_index(self->pending_paths, i))));
    }
    g_clear_pointer(&self->pending_paths, g_ptr_array_unref);
  }
  fl_method_call_respond_success(method_call, paths, nullptr);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  if (self->window != nullptr) {
    gtk_window_present(self->window);
    return;
  }

  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));
  self->window = window;

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "blastQR");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "blastQR");
  }

  gtk_window_set_default_size(window, 1280, 720);
  GdkGeometry min_size = {};
  min_size.min_width = 300;
  min_size.min_height = 300;
  gtk_window_set_geometry_hints(window, nullptr, &min_size, GDK_HINT_MIN_SIZE);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  g_autoptr(FlPluginRegistrar) registrar =
      fl_plugin_registry_get_registrar_for_plugin(FL_PLUGIN_REGISTRY(view),
                                                  "OpenFiles");
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  self->open_files_channel =
      fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                            "blastqr/open_files", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(
      self->open_files_channel, open_files_method_call_cb, self, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::open. Files opened in another instance arrive
// here too, since GApplication hands them to the first one.
static void my_application_open(GApplication* application, GFile** files,
                                gint n_files, const gchar* hint) {
  MyApplication* self = MY_APPLICATION(application);
  my_application_activate(application);

  g_autoptr(FlValue) paths = fl_value_new_list();
  for (gint i = 0; i < n_files; i++) {
    g_autofree gchar* path = g_file_get_path(files[i]);
    if (path == nullptr) continue;
    if (self->pending_paths != nullptr) {
      g_ptr_array_add(self->pending_paths, g_strdup(path));
    } else {
      fl_value_append_take(paths, fl_value_new_string(path));
    }
  }
  if (fl_value_get_length(paths) > 0) {
    fl_method_channel_invoke_method(self->open_files_channel, "open", paths,
                                    nullptr, nullptr, nullptr);
  }
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_object(&self->open_files_channel);
  g_clear_pointer(&self->pending_paths, g_ptr_array_unref);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->open = my_application_open;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->pending_paths = g_ptr_array_new_with_free_func(g_free);
}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  // Release builds run a single instance: opening files again hands them to
  // the running one. Debug builds don't, so `flutter run` always starts.
  GApplicationFlags flags = G_APPLICATION_HANDLES_OPEN;
#ifndef NDEBUG
  flags = static_cast<GApplicationFlags>(flags | G_APPLICATION_NON_UNIQUE);
#endif
  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", flags, nullptr));
}
