/*
Parametric dovetail cuts for CNC operations on wood.

To export to STL, use the follow command as a template:

    $ openscad -D PART=\"pins\" -D DOVETAILS=6 -D STOCK_WIDTH="3.5 * INCH" -o pins.stl dovetails.scad


Dovetail layout nspired by: http://www.startwoodworking.com/post/laying-out-dovetails


    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

// INCH constant in mm
INCH = 25.4;

// stock size
STOCK_THICKNESS = 0.75 * INCH;
STOCK_WIDTH        = 3.5   * INCH;
STOCK_LENGTH      = 24    * INCH;  // for asthetics; does not affect calculations

// how many dovetails
DOVETAILS = 5;

// how wide you want the narrow end of the pins (the tails will adjust)
// Recommended: 1/8" to 1/4", but you can go wider if you want
PIN_WIDTH = 0.125 * INCH;

// at what angle will the cuts be
// 8:1 or 6:1 (hardwoods or softwoods, respectively) ratio for the angle are common.
// HINT: take the arctangent of the fraction of your ratio to find the angle
ANGLE = atan(8/1);

//  Which part to display.
// Values can be one of:
//              "all": both boards are created
//              "pins": only board with pins is created
//              "tails": only board with tails is created
PART = "all";

// whether to render stock pieces as intersecting or apart
STOCK_INTERSECT = false;

// widths of each end of the pin
function pin_width_wide() = pin_width_narrow() + 2*(STOCK_THICKNESS/tan(ANGLE));
//function pin_width_wide() = STOCK_WIDTH/DOVETAILS*(R[1]/(R[0]+R[1]));
function pin_width_narrow() = PIN_WIDTH;

// widths of each end of the tail
function tail_width_wide() = (STOCK_WIDTH - pin_width_narrow()*(DOVETAILS+1))/DOVETAILS;
function tail_width_narrow() = tail_width_wide() - 2*(STOCK_THICKNESS/tan(ANGLE));

// width of where the tail and pin overlap
function tail_pin_overlap_width() = (tail_width_wide() - tail_width_narrow())/2;

// stock piece
module _stock() {
    cube(size=[STOCK_WIDTH, STOCK_LENGTH, STOCK_THICKNESS]);
}

// stock piece for pins
module pins_stock() {
    color("BurlyWood") _stock();
}

// stock piece for tails
module tails_stock() {
    color("SaddleBrown") _move_pins_or_pin_stock() _stock();
}

// tail solid model
module tail(cutter=true) {
    wide = tail_width_wide();
    narrow = tail_width_narrow();
    overlap = tail_pin_overlap_width();
    stock = STOCK_THICKNESS;
    extend = cutter ? 0.01 : 0.00;  // extend shape out a little in x, y, and z for better cutting results
    points = [[0, 0 -extend], [narrow, 0], [narrow + overlap, stock], [-overlap, stock]];
    translate([overlap, 0, -extend]) linear_extrude(height=stock + (2 * extend)) polygon(points=points);
}

// pin solid model
module pin(cutter=true) {
    wide = pin_width_wide();
    narrow = pin_width_narrow();
    overlap = tail_pin_overlap_width();
    stock = STOCK_THICKNESS;
    extend = cutter ? 0.01 : 0.00;  // extend shape out a little in x, y, and z for better cutting results
    points = [[0, -extend], [wide, -extend], [wide - overlap, stock + extend], [overlap, stock + extend]];
    translate([0, stock, 0]) rotate([90, 0, 0]) linear_extrude(height=stock + extend) polygon(points=points);
}

// DOVETAIL number of tails produced at proper spacing and positioning along stock edge
module tails_array() {
    offset = pin_width_narrow();
    for ( i = [0:DOVETAILS -1] ) {
        shift = (tail_width_wide()+ pin_width_narrow())*i;
        translate([offset + shift, 0, 0]) tail();
    }
}

module pins_array() {
    offset = -tail_pin_overlap_width();
    for ( i = [0:DOVETAILS] ) {
        shift = (tail_width_wide()+ pin_width_narrow())*i;
        _move_pins_or_pin_stock() translate([offset + shift, 0, 0]) pin();
    }
}

// moves a pin or the pin stock to the right location based on STOCK_INTERSECT value
module _move_pins_or_pin_stock() {
    if (STOCK_INTERSECT) {
        translate([0, 0, STOCK_THICKNESS]) rotate([-90, 0, 0]) children();
    } else {
        translate([STOCK_WIDTH + (3 * INCH), 0, 0]) children();
    }            
}

module pins_board() {
    color("SaddleBrown") difference() {
        pins_stock();
        tails_array();
    }
}

module tails_board() {
    color("BurlyWood") difference() {
        tails_stock();
        mirror([0, 0, STOCK_THICKNESS]) translate([0, 0, -STOCK_THICKNESS]) pins_array();
    }
}


if (PART == "all") {
    tails_board();
    pins_board();
} else if (PART == "tails") {
    tails_board();
} else if (PART == "pins") {
    pins_board();
}