# cargo, crew, and cockpit doors

var cargo_upper = aircraft.door.new("instrumentation/doors/cargodoorup", 3.0, 0);
var cargo_lower = aircraft.door.new("instrumentation/doors/cargodoor", 3.0, 0);

var (cargo_upper_state, cargo_lower_state) = (0, 0);

var cargo_upper_toggle = func {
    if (!getprop("/sim/weight[2]/installed")) {
        setprop("/sim/messages/copilot", "Opening or closing cargo door requires a cabin crew");
        return;
    }
    if (cargo_upper_state) {
        if (!cargo_lower_state) {
            cargo_upper.close();
            cargo_upper_state = 0;
        }
        else {
            setprop("/sim/messages/copilot", "Close loading ramp first");
        }
    }
    else {
        cargo_upper.open();
        cargo_upper_state = 1;
    }
};

# Position of the loading ramp when it is horizontal.
# 0 is fully closed, 1 is fully open.
var loading_ramp_horizontal_pos = 0.44;

# Position when the loading ramp is fully opened. Keep it a bit lower
# than 1.0 because otherwise it will touch or go through the ground.
var loading_ramp_max_pos = 0.9;

var loading_ramp_open = func {
    if (!getprop("/sim/weight[2]/installed")) {
        setprop("/sim/messages/copilot", "Opening or closing loading ramp requires a cabin crew");
        return;
    }
    if (cargo_upper_state) {
        if (cargo_lower_state == 0) {
            cargo_lower.move(loading_ramp_horizontal_pos);
            cargo_lower_state = 1;
        }
        elsif (cargo_lower_state == 1) {
            cargo_lower.move(loading_ramp_max_pos);
            cargo_lower_state = 2;
        }
    }
    else {
        setprop("/sim/messages/copilot", "Open cargo door first");
    }
};

var loading_ramp_close = func {
    if (!getprop("/sim/weight[2]/installed")) {
        setprop("/sim/messages/copilot", "Opening or closing loading ramp requires a cabin crew");
        return;
    }
    if (cargo_lower_state == 2) {
        cargo_lower.move(loading_ramp_horizontal_pos);
        cargo_lower_state = 1;
    }
    elsif (cargo_lower_state == 1) {
        cargo_lower.close();
        cargo_lower_state = 0;
    }
};

################################################################################

var crew_upper = aircraft.door.new("instrumentation/doors/crewup", 3.0, 0);
var crew_lower = aircraft.door.new("instrumentation/doors/crew", 3.0, 0);

var (crew_upper_state, crew_lower_state) = (0, 0);

# If the nacelles are tilted lower than this amount, then the upper
# starboard door cannot be opened in order to prevent the blades from
# causing someone to lose his head.
var starboard_door_tilt_limit = 45.0;

var crew_upper_toggle = func {
    if (!getprop("/sim/weight[2]/installed")) {
        setprop("/sim/messages/copilot", "Opening or closing starboard door requires a cabin crew");
        return;
    }
    if (crew_upper_state) {
        if (!crew_lower_state) {
            crew_upper.close();
            crew_upper_state = 0;
        }
        else {
            setprop("/sim/messages/copilot", "Close lower starboard door first");
        }
    }
    else {
        if (getprop("/sim/model/v22/tilt") > starboard_door_tilt_limit) {
            setprop("/sim/messages/copilot", sprintf("Cannot open upper starboard door when nacelles are tilted lower than %d degrees", starboard_door_tilt_limit));
        }
        else {
            crew_upper.open();
            crew_upper_state = 1;
        }
    }
};

var crew_lower_toggle = func {
    if (!getprop("/sim/weight[2]/installed")) {
        setprop("/sim/messages/copilot", "Opening or closing starboard door requires a cabin crew");
        return;
    }
    if (crew_lower_state) {
        crew_lower.close();
        crew_lower_state = 0;
    }
    else {
        if (crew_upper_state) {
            crew_lower.open();
            crew_lower_state = 1;
        }
        else {
            setprop("/sim/messages/copilot", "Open upper starboard door first");
        }
    }
};

var cockpit = aircraft.door.new("instrumentation/doors/cockpitdoor", 1.0, 0);

var cockpit_toggle = func {
    if (!getprop("/sim/weight[2]/installed") and !getprop("/sim/weight[4]/installed")) {
        setprop("/sim/messages/copilot", "Opening or closing cockpit door requires a cabin crew or flight engineer");
        return;
    }
    cockpit.toggle();
};

################################################################################

var internal_gearDown = controls.gearDown;

var aircraft_on_ground = func {
    return getprop("/gear/gear[0]/wow") or getprop("/gear/gear[1]/wow") or getprop("/gear/gear[2]/wow");
};

controls.gearDown = func (v) {
    if (v < 0 and aircraft_on_ground()) {
        setprop("/sim/messages/copilot", "Cannot move gear up while aircraft is on the ground");
    }
    else {
        internal_gearDown(v);
    }
};

################################################################################

var air_refuel = aircraft.door.new("instrumentation/doors/airrefuel", 4.0, 1);
var landinglightpos = aircraft.door.new("instrumentation/doors/landinglightpos", 4.0, 0);

setlistener("/instrumentation/doors/airrefuel/position-norm", func (node) {
    setprop("/instrumentation/doors/airrefuel/retract", node.getValue() == 1.0);
});
