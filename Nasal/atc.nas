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

var max = func(a, b) { a > b ? a : b }

var ChoiceListClass = {

    row_height: 16,

    new: func (content) {
        var m = {
            parents: [ChoiceListClass]
        };
        m.content = content;
        m.choices = [];
        return m;
    },

    add: func (choice) {
        append(me.choices, choice);
        me._update();
    },

    insert: func (choice, index) {
        me.choices = subvec(me.choices, 0, index) ~ [choice] ~ subvec(me.choices, index);
        me._update();
    },

    remove: func (index) {
        me.choices = subvec(me.choices, 0, index) ~ subvec(me.choices, index + 1);
        me._update();
    },

    remove_all: func {
        me.choices = [];
        me._update();
    },

    execute: func (index) {
        me.choices[index].execute();
    },

    _append_row: func (choice) {
        var index = size(me.content.node.getChildren("text"));

        var button = me.content.addChild("button");
        button.node.setValues({
            "legend": index + 1,
            "row": index,
            "col": 0,
            "halign": "right",
            "pref-height": ChoiceListClass.row_height - 2,
            "pref-width": ChoiceListClass.row_height - 2
        });
        button.setBinding("nasal", "atc.dialog.choice_list.execute(" ~ index ~ ")");

        var row = me.content.addChild("text");
        row.node.setValues({
            "label": choice.get_label(),
            "row": index,
            "col": 1,
            "halign": "fill",
            "pref-height": ChoiceListClass.row_height
        });
    },

    _update: func {
        me.content.node.removeChildren("button");
        me.content.node.removeChildren("text");

        foreach (var choice; me.choices) {
            me._append_row(choice);
        }

        # Redraw the window so that old choices are removed and new
        # choices are shown
        atc.dialog.redraw();
    }

};

var ATCChat = {

    name: "mp-atc-chat",

    window_width: 500,

    content_padding: 6,

    new: func (name) {
        var m = {
            parents: [ATCChat]
        };
        m.dialog = nil;
        m.content = nil;
        m.name = name;
        m.visible = 0;
        m.online = 0;
        m.on_ground = 1;

        return m;
    },

    create: func {
        if (me.dialog != nil) {
            me.del();
        };

        me.dialog = gui.dialog[me.name] = gui.Widget.new();
        me.dialog.set("name", me.name);
        me.dialog.set("dialog-name", me.name);
        me.dialog.set("pref-width", ATCChat.window_width);

        me.dialog.set("layout", "vbox");
        me.dialog.set("default-padding", 0);
        me.dialog.setColor(0, 0, 0, 0.3);

        var titlebar = me.dialog.addChild("group");
        titlebar.set("layout", "hbox");

        titlebar.addChild("empty").set("stretch", 1);
        titlebar.addChild("text").set("label", "ATC");
        titlebar.addChild("empty").set("stretch", 1);

        var close_button = titlebar.addChild("button");
        close_button.node.setValues({ "pref-width": 16, "pref-height": 16, legend: "", default: 0 });
        close_button.set("key", "Esc");
        close_button.setBinding("nasal", "atc.dialog.hide()");

        me.dialog.addChild("hrule");

        me.content = me.dialog.addChild("group");
        me.content.set("layout", "table");
        me.content.set("halign", "left");
        me.content.set("default-padding", ATCChat.content_padding);

        me.choice_list = ChoiceListClass.new(me.content);

        fgcommand("dialog-new", me.dialog.prop());
    },

    show: func {
        if (me.online) {
            fgcommand("dialog-show", me.dialog.prop());
            me.visible = 1;
        }
    },

    hide: func {
        fgcommand("dialog-close", me.dialog.prop());
        me.visible = 0;
    },

    toggle: func {
        if (me.visible) {
            me.hide();
        }
        else {
            me.show();
        }
    },

    del: func {
        me.hide();
        delete(gui.dialog, me.name);
    },

    _reset_position: func {
        var screen   = getprop("/sim/startup/ysize");
        var menubar  = getprop("/sim/menubar/visibility") ? 28 : 0;
        var margin   = 2;
        var titlebar = 25;

        var rows = size(me.content.node.getChildren("text"));

        # Take spacing into account if there are at least two rows
        var spacing = max(0, rows - 1) * 14;

        # Take padding into account if there is at least one row
        var padding = rows > 0 ? 2 * ATCChat.content_padding : 0;

        me.dialog.set("x", 2);
        me.dialog.set("y", screen - menubar - margin - titlebar - rows * ChoiceListClass.row_height - padding - spacing);
    },

    redraw: func {
        if (me.dialog != nil) {
            var was_visible = me.visible;

            me.hide();
            me._reset_position();

            if (was_visible) {
                me.show();
            }
        }
    },

    set_runway_takeoff_announcer: func (announcer) {
        announcer.connect("on-runway", me._on_runway);
        announcer.connect("approaching-runway", me._approaching_runway);
    },

    set_runway_landing_announcer: func (announcer) {
        announcer.connect("vacated-runway", me._vacated_runway);
    },

    set_online: func (is_online) {
        me.online = is_online;
        gui.menuEnable(me.name, is_online);

        if (!is_online) {
            me.hide();
        }
    },

    set_on_ground: func (on_ground) {
        me.on_ground = on_ground;
    },

    _on_runway: func (node) {
        var callsign = getprop("/sim/multiplay/callsign");
        me.send_message(sprintf("On runway %s, %s", node.getValue(), callsign));
    },

    _approaching_runway: func (node) {
        var callsign = getprop("/sim/multiplay/callsign");
        me.send_message(sprintf("Approaching runway %s, %s", node.getValue(), callsign));
    },

    _vacated_runway: func (node) {
        var callsign = getprop("/sim/multiplay/callsign");
        me.send_message(sprintf("Vacated runway %s, %s", node.getValue(), callsign));
    },

    send_message: func (message) {
        setprop("/sim/multiplay/chat", message);
    },

    receive_message: func (message) {
        var callsign = getprop("/sim/multiplay/callsign");
        var index = find(callsign ~ ": ", message);

        # if -1 then message was not meant for us
        # if 0 then message was sent by us
        if (index > 0) {
            foreach (var callsign_caller; keys(multiplayer.model.callsign)) {
                if (size(callsign_caller) + 2 == index and find(callsign_caller ~ ": ", message) == 0) {
                    var message_filtered = substr(message, index + size(callsign) + 2);
                    me._on_receive_message(callsign_caller, message_filtered);
                    break;
                }
            }
        }
    },

    _on_receive_message: func (sender, message) {
        var callsign = getprop("/sim/multiplay/callsign");

        foreach (var atc_message; atc.messages) {
            if (atc_message.is_instance(message)) {
                var value = atc_message.get_value(message);
                if (value != nil) {
                    me._display_readback(callsign, sender, sprintf(atc_message.get_response_format(), value));
                }
                else {
                    me.send_message(sprintf("%s: %s, %s", sender, atc_message.get_error_text(), callsign));
                }
                break;
            }
        }
    },

    _display_readback: func (callsign, sender, message) {
        me.choice_list.remove_all();
        me.choice_list.add(atc.ReadbackMessageChoiceClass.new(message, callsign, sender));
    }

};

var dialog = ATCChat.new(ATCChat.name);
dialog.create();

setlistener("/sim/startup/ysize", func (node) {
    dialog.redraw();
});

setlistener("/sim/signals/reinit-gui", func (node) {
    dialog.redraw();
});

setlistener("/sim/menubar/visibility", func (node) {
    dialog.redraw();
});

setlistener("/sim/multiplay/online", func (node) {
    dialog.set_online(node.getBoolValue());
}, startup=1, runtime=0);

setlistener("/sim/messages/mp-plane", func (node) {
    dialog.receive_message(node.getValue());
});
