import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'request_maker.dart';

// This is the list of services/tasks provided by the backend
typedef Rt = RequestUnitType;

const task_items = [
  (
    endpoint: "task/save_video",
    request_fields : <RequestInputType>[
      (field_name: "video", type: Rt.video, nullable: false),
    ]
  ),
  (
      endpoint: "task/get_video",
      request_fields: <RequestInputType>[]
  ),
  (
    endpoint: "task/restore_video",
    request_fields : <RequestInputType>[
    ]
  ),
  (
    endpoint: "task/clear_last_video",
    request_fields : <RequestInputType>[
      (field_name: "video", type: Rt.video, nullable: false),
    ]
  ),
  (
    endpoint: "task/query_info",
    request_fields : <RequestInputType>[
      (field_name: "video", type: Rt.video, nullable: true),
    ]
  ),
  (
    endpoint: "task/select_frames",
    request_fields : <RequestInputType>[
      (field_name: "video", type: Rt.video, nullable: true),
      (field_name: "frames", type: Rt.integer, nullable: false),
    ]
  ),
  (
    endpoint: "task/select_at_fps",
    request_fields : <RequestInputType>[
      (field_name: "video", type: Rt.video, nullable: true),
      (field_name: "fps", type: Rt.integer, nullable: false),
    ]
  ),
  (
    endpoint: "task/draw_landmarks",
    request_fields : <RequestInputType>[
      (field_name: "video", type: Rt.video, nullable: true),
    ]
  ),
  (
    endpoint: "task/downsample_it",
    request_fields : <RequestInputType>[
      (field_name: "video", type: Rt.video, nullable: true),
      (field_name: "factor", type: Rt.integer, nullable: false),
    ]
  ),
  (
    endpoint: "task/play_video",
    request_fields : <RequestInputType>[
      (field_name: "video", type: Rt.video, nullable: true),
      (field_name: "fps", type: Rt.integer, nullable: true),
      (field_name: "frames", type: Rt.integer, nullable: true),
    ]
  ),
];
