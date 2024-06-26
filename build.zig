const std = @import("std");
const statically = @import("statically");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    _ = statically.option(b);
    statically.log("libcamera");

    const libyaml = statically.dependency(b, "libyaml", target, optimize).artifact("yaml");

    const options = .{
        .name = "camera",
        .target = target,
        .optimize = optimize,
    };

    const lib = statically.library(b, options, options);

    lib.linkLibCpp();
    lib.linkLibrary(libyaml);

    const private_flag = &.{
        "-DLIBCAMERA_BASE_PRIVATE",
    };

    lib.addCSourceFiles(.{ .files = src, .flags = private_flag });
    lib.addCSourceFiles(.{ .files = base_src, .flags = private_flag });

    // Ideally, we'd have some sort of Zig script do this but it's okay.
    // Creates the control_ids.h file.
    const python3_gen_control_ids = b.addSystemCommand(&.{
        "python3",
        "utils/gen-controls.py",
        "-o",
        "include/libcamera/control_ids.h",
        "--mode",
        "controls",
        "-t",
        "include/libcamera/control_ids.h.in",
        "-r",
        "src/libcamera/control_ranges.yaml",
        "src/libcamera/control_ids_draft.yaml",
        "src/libcamera/control_ids_core.yaml",
        "src/libcamera/control_ids_rpi.yaml",
    });
    b.getInstallStep().dependOn(&python3_gen_control_ids.step);

    // Creates the control_ids.h file.
    const python3_gen_property_ids = b.addSystemCommand(&.{
        "python3",
        "utils/gen-controls.py",
        "-o",
        "include/libcamera/property_ids.h",
        "--mode",
        "properties",
        "-t",
        "include/libcamera/property_ids.h.in",
        "-r",
        "src/libcamera/control_ranges.yaml",
        "src/libcamera/property_ids_draft.yaml",
        "src/libcamera/property_ids_core.yaml",
    });
    lib.step.dependOn(&python3_gen_property_ids.step);

    // Creates the formats.h file.
    const python3_gen_formats = b.addSystemCommand(&.{
        "python3",
        "utils/gen-formats.py",
        "-o",
        "include/libcamera/formats.h",
        "src/libcamera/formats.yaml",
        "include/libcamera/formats.h.in",
        "include/linux/drm_fourcc.h",
    });
    lib.step.dependOn(&python3_gen_formats.step);

    const shell_libcamera_header = b.addSystemCommand(&.{
        "utils/gen-header.sh",
        "include/libcamera",
        "include/libcamera/libcamera.h",
    });
    lib.step.dependOn(&shell_libcamera_header.step);

    lib.addIncludePath(b.path("include"));
    // /include/libcamera dir
    lib.installHeader(b.path("include/libcamera/camera.h"), "camera.h");
    lib.installHeader(b.path("include/libcamera/camera_manager.h"), "camera_manager.h");
    lib.installHeader(b.path("include/libcamera/color_space.h"), "color_space.h");
    lib.installHeader(b.path("include/libcamera/controls.h"), "controls.h");
    lib.installHeader(b.path("include/libcamera/fence.h"), "fence.h");
    lib.installHeader(b.path("include/libcamera/framebuffer.h"), "framebuffer.h");
    lib.installHeader(b.path("include/libcamera/framebuffer_allocator.h"), "framebuffer_allocator.h");
    lib.installHeader(b.path("include/libcamera/geometry.h"), "geometry.h");
    lib.installHeader(b.path("include/libcamera/logging.h"), "logging.h");
    lib.installHeader(b.path("include/libcamera/orientation.h"), "orientation.h");
    lib.installHeader(b.path("include/libcamera/pixel_format.h"), "pixel_format.h");
    lib.installHeader(b.path("include/libcamera/request.h"), "request.h");
    lib.installHeader(b.path("include/libcamera/stream.h"), "stream.h");
    lib.installHeader(b.path("include/libcamera/transform.h"), "transform.h");
    // install generated headers
    lib.installHeader(b.path("include/libcamera/formats.h"), "formats.h");
    lib.installHeader(b.path("include/libcamera/control_ids.h"), "control_ids.h");
    lib.installHeader(b.path("include/libcamera/property_ids.h"), "property_ids.h");
    lib.installHeader(b.path("include/libcamera/libcamera.h"), "libcamera.h");

    // /include/libcamera/base dir
    lib.installHeader(b.path("include/libcamera/base/bound_method.h"), "bound_method.h");
    lib.installHeader(b.path("include/libcamera/base/class.h"), "class.h");
    lib.installHeader(b.path("include/libcamera/base/compiler.h"), "compiler.h");
    lib.installHeader(b.path("include/libcamera/base/flags.h"), "flags.h");
    lib.installHeader(b.path("include/libcamera/base/object.h"), "object.h");
    lib.installHeader(b.path("include/libcamera/base/shared_fd.h"), "shared_fd.h");
    lib.installHeader(b.path("include/libcamera/base/signal.h"), "signal.h");
    lib.installHeader(b.path("include/libcamera/base/span.h"), "span.h");
    lib.installHeader(b.path("include/libcamera/base/unique_fd.h"), "unique_fd.h");

    b.installArtifact(lib);
}

const src = &.{
    "src/libcamera/bayer_format.cpp",
    "src/libcamera/byte_stream_buffer.cpp",
    "src/libcamera/camera.cpp",
    "src/libcamera/camera_controls.cpp",
    "src/libcamera/camera_lens.cpp",
    "src/libcamera/camera_manager.cpp",
    "src/libcamera/color_space.cpp",
    "src/libcamera/control_serializer.cpp",
    "src/libcamera/control_validator.cpp",
    "src/libcamera/controls.cpp",
    "src/libcamera/converter.cpp",
    "src/libcamera/delayed_controls.cpp",
    "src/libcamera/device_enumerator.cpp",
    "src/libcamera/device_enumerator_sysfs.cpp",
    "src/libcamera/device_enumerator_udev.cpp",
    "src/libcamera/dma_buf_allocator.cpp",
    "src/libcamera/fence.cpp",
    "src/libcamera/formats.cpp",
    "src/libcamera/framebuffer.cpp",
    "src/libcamera/framebuffer_allocator.cpp",
    "src/libcamera/geometry.cpp",
    // Wants IPA definitions.
    //"src/libcamera/ipa_controls.cpp",
    //"src/libcamera/ipa_data_serializer.cpp",
    //"src/libcamera/ipa_interface.cpp",
    //"src/libcamera/ipa_manager.cpp",
    //"src/libcamera/ipa_module.cpp",
    //"src/libcamera/ipa_proxy.cpp",
    "src/libcamera/ipc_pipe.cpp",
    "src/libcamera/ipc_unixsocket.cpp",
    "src/libcamera/ipc_pipe_unixsocket.cpp",
    "src/libcamera/mapped_framebuffer.cpp",
    "src/libcamera/media_device.cpp",
    "src/libcamera/media_object.cpp",
    "src/libcamera/orientation.cpp",
    // Wants libcamera/internal/tracepoints.h.
    //"src/libcamera/pipeline_handler.cpp",
    "src/libcamera/pixel_format.cpp",
    "src/libcamera/process.cpp",
    "src/libcamera/pub_key.cpp",
    // Wants libcamera/internal/tracepoints.h.
    //"src/libcamera/request.cpp",
    "src/libcamera/shared_mem_object.cpp",
    "src/libcamera/source_paths.cpp",
    "src/libcamera/stream.cpp",
    "src/libcamera/sysfs.cpp",
    // Wants libcamera/internal/tracepoints.h.
    //"src/libcamera/tracepoints.cpp",
    "src/libcamera/transform.cpp",
    "src/libcamera/v4l2_device.cpp",
    "src/libcamera/v4l2_pixelformat.cpp",
    "src/libcamera/v4l2_subdevice.cpp",
    "src/libcamera/v4l2_videodevice.cpp",
    "src/libcamera/yaml_parser.cpp",
};

const base_src = &.{
    "src/libcamera/base/backtrace.cpp",
    "src/libcamera/base/bound_method.cpp",
    "src/libcamera/base/class.cpp",
    "src/libcamera/base/event_dispatcher.cpp",
    "src/libcamera/base/event_notifier.cpp",
    "src/libcamera/base/file.cpp",
    "src/libcamera/base/flags.cpp",
    "src/libcamera/base/log.cpp",
    "src/libcamera/base/message.cpp",
    "src/libcamera/base/mutex.cpp",
    "src/libcamera/base/object.cpp",
    "src/libcamera/base/semaphore.cpp",
    "src/libcamera/base/shared_fd.cpp",
    "src/libcamera/base/signal.cpp",
    "src/libcamera/base/thread.cpp",
    "src/libcamera/base/timer.cpp",
    "src/libcamera/base/unique_fd.cpp",
    "src/libcamera/base/utils.cpp",
};
