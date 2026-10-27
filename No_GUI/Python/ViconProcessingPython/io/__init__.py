"""Motion-capture file I/O."""

from .c3d import markersto_c3d, read_c3d, trc_to_c3d, write_c3d

__all__ = ["markersto_c3d", "read_c3d", "trc_to_c3d", "write_c3d"]
