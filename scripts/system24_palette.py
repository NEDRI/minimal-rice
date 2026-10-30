#!/usr/bin/env python3
"""system24 palette (refact0r/system24, OKLCH converted to sRGB), as (r, g, b) per colour name."""

PALETTE = {
    "text-1": (238, 238, 238),
    "text-2": (206, 206, 206),
    "text-3": (174, 174, 174),
    "text-4": (128, 128, 128),
    "text-5": (72, 72, 72),
    "bg-1": (48, 48, 48),
    "bg-2": (38, 38, 38),
    "bg-3": (29, 29, 29),
    "bg-4": (20, 20, 20),
    "red-1": (240, 137, 170),
    "red-2": (223, 122, 155),
    "red-3": (206, 106, 140),
    "red-4": (189, 91, 125),
    "red-5": (172, 76, 110),
    "green-1": (79, 198, 162),
    "green-2": (59, 182, 147),
    "green-3": (36, 166, 132),
    "green-4": (0, 151, 117),
    "green-5": (17, 134, 89),
    "blue-1": (73, 191, 217),
    "blue-2": (53, 175, 201),
    "blue-3": (26, 160, 185),
    "blue-4": (0, 144, 169),
    "blue-5": (0, 129, 153),
    "yellow-1": (220, 186, 92),
    "yellow-2": (203, 170, 75),
    "yellow-3": (187, 155, 57),
    "yellow-4": (172, 139, 38),
    "yellow-5": (156, 124, 11),
    "purple-1": (197, 152, 231),
    "purple-2": (181, 137, 214),
    "purple-3": (166, 121, 198),
    "purple-4": (150, 106, 181),
    "purple-5": (135, 92, 165),
}


def palette():
    return dict(PALETTE)


if __name__ == "__main__":
    for k, (r, g, b) in PALETTE.items():
        print(f"{k:10s} {r:3d},{g:3d},{b:3d}  #{r:02x}{g:02x}{b:02x}")
