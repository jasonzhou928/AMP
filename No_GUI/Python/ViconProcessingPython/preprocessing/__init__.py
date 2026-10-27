"""Preprocessing primitives ported from the MATLAB Vicon pipeline."""

from .quality import (
    FindAGoodFrame,
    FindAGoodFrameByCluster,
    checkForMissingClusters,
    check_for_missing_clusters,
    find_a_good_frame,
    find_a_good_frame_by_cluster,
)
from .relinking import (
    predict_future_positions,
    relink_marker_segments,
    relink_trimmed_neighbor,
    relink_trimmed_pattern,
    relink_trimmed_rigid_body,
    relinkMarkerSegmentation,
    relinkTrimmedMarkerSegmentationNeighbor,
    relinkTrimmedMarkerSegmentationPattern2,
    relinkTrimmedMarkerSegmentationRigidBody,
    replace_current_marker_with_cmarker,
    replaceCurrentMarkersWithCMarkers,
)
from .segmentation import (
    CmarkerJumpSegmentation,
    markerJumpSegmentation,
    segment_cmarker_jumps,
    segment_marker_jumps,
    segment_markers,
    segment_single_marker,
    segmentMarkers,
    segmentSingleMarker,
)
from .trials import (
    CombineUnlabeledMarkers,
    combine_trial_segments,
    combine_unlabeled_markers,
    combineTrialsSegments,
    crop_trial_segments,
    cropTrialsSegments,
)

__all__ = [name for name in globals() if not name.startswith("_")]
