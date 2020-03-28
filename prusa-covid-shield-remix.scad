// -*- mode: scad; c-basic-offset: 2; indent-tabs-mode:nil -*-
// Incoroprating some feedback from local healthcare providers
//   * weight-reducing of front-part if possible.
//   * Move the shield buttons up so that there is material behind the openings
//     of the shield-punches

$fn=32;
e=0.01;

do_front_punch_holes = true;   // For lightness
do_back_punch_holes=true;
thinner_band=false;
provide_pin_support = false;    // Printing support.

band_thick=thinner_band ? 15 : 20;
front_hole_r = thinner_band ? 4 : 6;

// mm to move the pin up
vertical_pin_shift=7;  // mm
version="⬡1";   // Keep it short, so that it only is on the flat end.

module baseline_headband() {
  // The distribted RC2 STL file is pretty shifted...
  translate([7.8, 9, 2.5]) import("baseline/covid19_headband_rc3.stl", convexity=10);
}

module maker_nexus_baseline_headband() {
  difference() {
    if (thinner_band) {
      scale([1, 1, 0.75]) baseline_headband();
    } else {
      baseline_headband();
    }

    // Maker nexus version number.
    translate([85.4, -38, 0.5]) {
      rotate([90, 0, -90]) linear_extrude(height=10) text("M", size=5, halign="center", font="style:Bold");
      translate([0, 0, -7]) rotate([90, 0, -90]) linear_extrude(height=10) text("N", size=6, halign="center", font="style:Bold");
    }
    translate([85.7, -60, -4]) rotate([90, 0, -90]) linear_extrude(height=10) text(version, size=8, halign="right", font="style:Bold");
  }
}

module hole_punch(angle=0, r=front_hole_r, dist=70) {
  rotate([0, 0, angle]) translate([0, dist, 0])
    rotate([-90, 0, 0]) rotate([0, 0, 30]) cylinder(r=r, h=20, $fn=6);
}

// A headband that is lighter due to cutout-holes
module light_headband() {
  angle_distance=11;  // degrees at which we punch our weight-reduce hole.
  difference() {
    maker_nexus_baseline_headband();
    if (do_front_punch_holes) {
      for (i = [-5:1:+5]) {
        // Punch holes exect in places of need of stabiliity.
        if (abs(i) != 2) hole_punch(i * angle_distance, r=front_hole_r, dist=70);
      }

      if (do_back_punch_holes) {
        translate([0, -40, 0]) for (i = [-7:1:+7]) {
          hole_punch(i * 10, r=front_hole_r-1, dist=68);
        }
      }
    }
  }
}

// Support for the pins.
module support_column(angle=0, dist=0, last=true, wall_thick=0.75) {
  r=5;
  support_platform=vertical_pin_shift-0.3 - (thinner_band ? 2.5 : 0);
  h=last ? support_platform : stack_distance;
  color("yellow") rotate([0, 0, angle]) translate([0, dist, -band_thick/2])
    rotate([0, 0, 180]) {
    difference() {
      union() {
        cylinder(r=r, h=h);
        //translate([-r, 0, 0]) cube([2*r, 0.5*r, h]);
      }
      translate([0, 0, -e]) union() {
        translate([0, 0, -0.5]) cylinder(r=r-wall_thick, h=h+2*e);
        translate([-r, +wall_thick, 0]) cube([2*r, r, h+2*e]);
      }
    }
    //translate([-r, -1, support_platform-0.5]) cube([2*r, 3, 0.5]);
  }
}

// The angle and distance the pins. We only need some rough position,
// as we just use this as a cut-out where we do the material-move operation.
// There we just move the bottom part up and replace the bottom part with
// what we found above (angles, positions determined empirically)
pin_angle_distances = [ [21.5, 80], [-21.5, 80], [76, 93], [-76, 93]];

module shield_pin_vertical_cutout(extra=0) {
  b_size = 10 + extra;
  translate([0, 0, -10+b_size/2]) cube([b_size, 15, b_size], center=true);
}

// A region of interest at the given angle and distance.
module roi_block(angle, dist, extra=0) {
  rotate([0, 0, angle]) translate([0, dist, 0])
    shield_pin_vertical_cutout(extra);
}

module print_shield() {
  // Cut out the area with the pins and move them up.
  translate([0, 0, vertical_pin_shift]) intersection() {
    baseline_headband();  // Baseline has the right sized pins.
    for (x = pin_angle_distances) roi_block(x[0], x[1]);
  }

  // Now, take the _top_ part of the band by doing the same cut-out ont
  // the same band lying on its back and use that to fill the hole at
  // the bottom left from the pin being shifted up.
  // Using the rotational cut-out means we capture the taper the band
  // has and replicate it fully at the bottom.
  intersection() {
    rotate([0, 180, 0]) light_headband();
    for (x = pin_angle_distances) roi_block(x[0], x[1]);
  }

  // Combine the above that with the shield, but leave out the pin area
  // we were 'operating' on: that is now filled with our construct above.
  difference() {
    light_headband();
    for (x = pin_angle_distances) roi_block(x[0], x[1], extra=-1);
  }

  // Add support for the pins.
  if (provide_pin_support) {
    for (x = pin_angle_distances) support_column(x[0], x[1]+3);
  }
}

// Places where we need support are the places where our region-of-interest
// blocks are. We use the STL generated from these to tell Prusa-Slicer where
// we want the support.
module support_modifier() {
  for (x = pin_angle_distances) roi_block(x[0], x[1]);
}

// For visualization. The Makefile creates all the relevant artifacts.
print_shield();
