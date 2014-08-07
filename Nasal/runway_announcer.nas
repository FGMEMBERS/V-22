# Copyright (C) 2014  onox
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

var sin = func(a) { math.sin(a * math.pi / 180.0) }
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var max = func(a, b) { a > b ? a : b }

var Observable = {

    new: func {
        var m = {
            parents: [Observable]
        };
        m.observers = {};
        return m;
    },

    connect: func (signal, callback) {
        if (!contains(me.observers, signal)) {
            me.observers[signal] = [];
        }
        append(me.observers[signal], callback);
    },

    notify_observers: func (signal, arguments) {
        if (contains(me.observers, signal)) {
            foreach (var observer; me.observers[signal]) {
                observer(arguments);
            }
        }
    }
};

var RunwayAnnounceClass = {

    new: func {
        var m = {
            parents: [RunwayAnnounceClass, Observable.new()]
        };
        m.mode = "";
        return m;
    },

    set_mode: func (mode) {
        # Set the mode. Depending on the mode this object will or
        # will not notify certain observers.

        me.mode = mode;

        if (mode != '') {
            logger.warn(sprintf("Set mode to %s", mode));
        }
        else {
            logger.warn("Reset mode");
        }
    },

    _check_runway: func (apt, runway, self) {
        self.set_alt(apt.elevation);

        var rwy = apt.runway(runway);
        var rwy_coord = geo.Coord.new().set_latlon(rwy.lat, rwy.lon, apt.elevation);

        var rwy_start_coord = geo.Coord.new().set(rwy_coord);

        # Modify current coord by applying a heading and RWY length to
        # transform it to the opposite RWY
        rwy_coord.apply_course_distance(rwy.heading, rwy.length);

        var distance = self.distance_to(rwy_coord);
        var course = self.course_to(rwy_coord);

        var crosstrack_error = distance * abs(sin(course - rwy.heading));
        var distance_stop = distance * cos(course - rwy.heading);
        var edge_rem = max(rwy.width / 2, crosstrack_error) - rwy.width / 2;

        var on_rwy = edge_rem == 0 and 0 <= distance_stop and distance_stop <= rwy.length;

        var distance_start = self.distance_to(rwy_start_coord);

        return {
            on_runway:          on_rwy,
            # True if on the runway, false otherwise

            distance_stop:      distance_stop,
            # Distance to the edge of the opposite runway. The distance
            # is parallel to the runway.

            crosstrack_error:   crosstrack_error,
            # Distance to the center line of the runway. The distance
            # is orthogonal to the center line.

            edge_rem:           edge_rem,
            # Distance from outside the runway to the nearest side edge
            # of the RWY. 0 if on_runway is true. Orthogonal to the runway.

            distance_start:     distance_start
            # Distance to the center of the starting position on the
            # runway. This is a direct line; not parallel or orthogonal.
        };
    }

};

var TakeoffRunwayAnnounceConfig = {

    distance_start_m: 200,
    # The maximum distance in meters from the starting position
    # on the runway. Large runways are usually 40 to 60 meters wide.

    diff_runway_heading_deg: 10,
    # Difference in heading between runway and aircraft in order to
    # get an announcement that the aircraft is on the runway for takeoff.

    diff_approach_heading_deg: 60,
    # Maximum angle at which the aircraft should approach the runway.
    # Must be higher than 0 and lower than 90.

    distance_center_line_m: 10,
    # The distance in meters from the center line of the runway

    distance_edge_min_m: 20,
    distance_edge_max_m: 100,
    # Minimum and maximum distance in meters from the edge of the runway
    # for announcing approaches.

};

var TakeoffRunwayAnnounceClass = {
    # Announce when approaching a runway or when on a runway ready for
    # takeoff. Valid modes and the signals they emit are:
    #
    # - taxi:               approaching-runway
    # - taxi-and-takeoff:   approaching-runway, on-runway
    # - takeoff:            on-runway

    new: func (config) {
        var m = {
            parents: [TakeoffRunwayAnnounceClass, RunwayAnnounceClass.new()]
        };
        m.timer = maketimer(0.5, func m._check_position());
        m.config = config;

        m.last_announced_runway = "";
        m.last_announced_approach = "";

        return m;
    },

    start: func {
        # Start monitoring the location of the aircraft relative to the
        # runways of the current airport.

        me.timer.start();
    },

    stop: func {
        # Stop monitoring the location of the aircraft.
        #
        # You should call this function after takeoff.

        me.timer.stop();

        me.last_announced_runway = "";
        me.last_announced_approach = "";
    },

    _check_position: func {
        if (me.mode == "") {
            return;
        }

        var apt = airportinfo();

        var approaching_runways = {};

        foreach (var runway; keys(apt.runways)) {
            var self = geo.aircraft_position();
            var result = me._check_runway(apt, runway, self);

            var self_heading = getprop("/orientation/heading-deg");
            var runway_heading = apt.runway(runway).heading;

            # Reset flag for announced approaching runway, so that
            # the airplane could turn around, approach the same runway,
            # and read/hear the announcement again
            if (runway == me.last_announced_approach
              and result.edge_rem > me.config.distance_edge_max_m) {
                me.last_announced_approach = "";
            }

            if (result.on_runway) {
                if (me.mode == "taxi-and-takeoff" or me.mode == "takeoff") {
                    var heading_diff = abs(self_heading - runway_heading);
                    if (heading_diff <= me.config.diff_runway_heading_deg
                      and result.distance_start <= me.config.distance_start_m
                      and result.crosstrack_error <= me.config.distance_center_line_m) {
                        if (me.last_announced_runway != runway) {
                            me.notify_observers("on-runway", runway);
                            me.last_announced_runway = runway;
                        }
                    }
                }
            }
            else {
                if (me.mode == "taxi-and-takeoff" or me.mode == "taxi") {
                    if (me.config.distance_edge_min_m <= result.edge_rem
                      and result.edge_rem <= me.config.distance_edge_max_m) {
                        var ac_angle1 = cos(90.0 - (math.mod(runway_heading, 180) - self_heading));
                        var ac_angle2 = cos(90.0 - (self_heading - math.mod(runway_heading, 180)));
                        var ac_angle = max(ac_angle1, ac_angle2);

                        if (ac_angle > 0 and ac_angle >= cos(me.config.diff_approach_heading_deg)) {
                            self.apply_course_distance(self_heading, result.crosstrack_error / ac_angle);
                            var result_future = me._check_runway(apt, runway, self);

                            # If in the future we are on the runway, we are approaching it
                            if (result_future.on_runway) {
                                approaching_runways[runway] = result.distance_start;
                            }
                        }
                    }
                }
            }
        }

        # Every runway also has an opposite runway. Choose the runway that
        # is closest to the aircraft.
        if (size(approaching_runways) == 2) {
            var start_distance_compare = func (a, b) {
                return approaching_runways[a] - approaching_runways[b];
            };
            closest_runway = sort(keys(approaching_runways), start_distance_compare);

            runway = closest_runway[0];
            if (me.last_announced_approach != runway) {
                me.notify_observers("approaching-runway", runway);
                me.last_announced_approach = runway;
            }
        }
    }

};

var LandingRunwayAnnounceConfig = {

    distances: [30, 100, 300, 600, 900, 1200, 2000, 3000, 4000],

    diff_runway_heading_deg: 15,
    # Difference in heading between runway and aircraft in order to
    # detect the correct runway on which the aircraft is landing.

};

var LandingRunwayAnnounceClass = {

    period: 0.1,

    # Announce remaining distance after landing on a runway. Valid modes
    # and the signals they emit are:
    #
    # - landing: remaining-distance, landed-runway, vacated-runway, landed-outside-runway

    new: func (config) {
        var m = {
            parents: [LandingRunwayAnnounceClass, RunwayAnnounceClass.new()]
        };
        m.timer = maketimer(LandingRunwayAnnounceClass.period, func m._check_position());
        m.config = config;

        m.last_announced_runway = "";
        m.landed_runway = "";
        m.distances = nil;

        return m;
    },

    start: func {
        # Start monitoring the location of the aircraft on the runway.

        me.timer.start();
    },

    stop: func {
        # Stop monitoring the location of the aircraft.
        #
        # You should call this function after vacating the runway.

        me.set_mode("");

        me.timer.stop();

        me.last_announced_runway = "";
        me.landed_runway = "";
        me.distances = nil;
    },

    _check_position: func {
        if (me.mode == "") {
            return;
        }

        var apt = airportinfo();
        
        var on_number_of_rwys = 0;

        foreach (var runway; keys(apt.runways)) {
            var self = geo.aircraft_position();
            var result = me._check_runway(apt, runway, self);

            var self_heading = getprop("/orientation/heading-deg");
            var runway_heading = apt.runway(runway).heading;

            if (result.on_runway) {
                on_number_of_rwys += 1;

                if (me.mode == "landing") {
                    if (me.landed_runway == "") {
                        var heading_diff = abs(self_heading - runway_heading);
                        if (heading_diff <= me.config.diff_runway_heading_deg) {
                            me.landed_runway = runway;
                            me.distances = me.config.distances;
                            me.notify_observers("landed-runway", runway);
                        }
                    }

                    if (runway == me.landed_runway) {
                        var mps = getprop("/velocities/uBody-fps") * 0.3048;
                        var dist_upper = pop(me.distances);
                        if (dist_upper != nil) {
                            # Distance travelled in two timer periods
                            var dist_lower = dist_upper - mps * LandingRunwayAnnounceClass.period * 2;

                            if (dist_lower <= result.distance_stop and result.distance_stop <= dist_upper) {
                                me.notify_observers("remaining-distance", dist_upper);
                            }
                            elsif (dist_upper < result.distance_stop) {
                                append(me.distances, dist_upper);
                            };
                        }
                    }
                }
            }
            else {
                if (me.mode == "landing" and runway == me.landed_runway) {
                    me.distances = nil;
                    if (me.last_announced_runway != runway) {
                        me.notify_observers("vacated-runway", runway);
                        me.last_announced_runway = runway;
                    }
                }
            }
        }
        
        # Make landed_runway nil to prevent emitting landed-runway signal
        # in case we landed on anything but a runway (taxiway for example)
        if (me.mode == "landing" and on_number_of_rwys == 0) {
            if (me.landed_runway == "") {
                me.notify_observers("landed-outside-runway", nil);
            }
            me.landed_runway = nil;
        }
    }

};