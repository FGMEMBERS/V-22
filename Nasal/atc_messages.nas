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

var AbstractATCMessageClass = {

    new: func {
        var m = {
            parents: [AbstractATCMessageClass]
        };
        return m;
    },

    is_instance: func (message) {
        return find (me.text, message) == 0;
    },

    get_error_text: func {
        return me.error_text;
    },

    get_response_format: func {
        return me.response_format;
    }

};

var AbstractHeadingATCMessageClass = {

    new: func {
        var m = {
            parents: [AbstractHeadingATCMessageClass, AbstractATCMessageClass.new()]
        };
        m.error_text = "Unable, invalid heading";
        return m;
    },

    get_value: func (message) {
        var heading = int(substr(message, size(me.text)));
        return (heading != nil and heading >= 0 and heading <= 359) ? heading : nil;
    }

};

var HeadingLeftATCMessageClass = {

    new: func {
        var m = {
            parents: [HeadingLeftATCMessageClass, AbstractHeadingATCMessageClass.new()]
        };
        m.text = "Turn left heading: ";
        m.response_format = "Turning left heading %03d";
        return m;
    }

};

var HeadingRightATCMessageClass = {

    new: func {
        var m = {
            parents: [HeadingRightATCMessageClass, AbstractHeadingATCMessageClass.new()]
        };
        m.text = "Turn right heading: ";
        m.response_format = "Turning right heading %03d";
        return m;
    }

};

var AbstractFlightLevelATCMessageClass = {

    new: func {
        var m = {
            parents: [AbstractFlightLevelATCMessageClass, AbstractATCMessageClass.new()]
        };
        m.error_text = "Unable, invalid flight level";
        return m;
    },

    get_value: func (message) {
        var fl_str = substr(message, size(me.text));

        if (find(" ", fl_str) == 0) {
            var fl = int(substr(fl_str, 1));
        }
        else {
            var fl = int(fl_str);
        }

        return (fl != nil and fl >= 0 and fl <= 999) ? fl : nil;
    }

};

var ClimbFlightLevelATCMessageClass = {

    new: func {
        var m = {
            parents: [ClimbFlightLevelATCMessageClass, AbstractFlightLevelATCMessageClass.new()]
        };
        m.text = "Climb and maintain: FL";
        m.response_format = "Climbing to FL%03d";
        return m;
    }

};

var DescendFlightLevelATCMessageClass = {

    new: func {
        var m = {
            parents: [DescendFlightLevelATCMessageClass, AbstractFlightLevelATCMessageClass.new()]
        };
        m.text = "Descend and maintain: FL";
        m.response_format = "Descending to FL%03d";
        return m;
    }

};

var AbstractAltitudeATCMessageClass = {

    new: func {
        var m = {
            parents: [AbstractAltitudeATCMessageClass, AbstractATCMessageClass.new()]
        };
        m.error_text = "Unable, invalid altitude";
        return m;
    },

    get_value: func (message) {
        var altitude_str = substr(message, size(me.text));
        
        if (find(" ft", altitude_str) == size(altitude_str) - 3) {
            var altitude = int(substr(altitude_str, 0, size(altitude_str) - 3));
            debug.dump(altitude_str);
            debug.dump(substr(altitude_str, 0, size(altitude_str) - 3));
        }
        elsif (find("ft", altitude_str) == size(altitude_str) - 2) {
            var altitude = int(substr(altitude_str, 0, size(altitude_str) - 2));
        }
        else {
            var altitude = int(altitude_str);
        }

        return (altitude != nil and altitude >= 0 and altitude <= 99999) ? altitude : nil;
    }

};

var ClimbAltitudeATCMessageClass = {

    new: func {
        var m = {
            parents: [ClimbAltitudeATCMessageClass, AbstractAltitudeATCMessageClass.new()]
        };
        m.text = "Climb and maintain: ";
        m.response_format = "Climbing to %5d";
        return m;
    }

};

var DescendAltitudeATCMessageClass = {

    new: func {
        var m = {
            parents: [DescendAltitudeATCMessageClass, AbstractAltitudeATCMessageClass.new()]
        };
        m.text = "Descend and maintain: ";
        m.response_format = "Descending to %5d";
        return m;
    }

};

var messages = [
    HeadingLeftATCMessageClass.new(),
    HeadingRightATCMessageClass.new(),
    ClimbFlightLevelATCMessageClass.new(),
    DescendFlightLevelATCMessageClass.new(),
    ClimbAltitudeATCMessageClass.new(),
    DescendAltitudeATCMessageClass.new(),
];
