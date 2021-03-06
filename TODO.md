* [x] Use moving average filter for ground contact logic
* [x] Use ground contact logic for enabling/disabling FBW pitch modes
* [ ] Add Differential Swashplate Tilt (DST) factors for VTOL rudder input
    * [x] Add factor using nacelles tilt
    * [ ] Add factor using airspeed
* [x] Add g force protection to Pitch Rate controller (min. and max. functions have already been added)
* [x] Implement lateral cyclic movement for VTOL aileron input using the LSG factors
* [ ] Phase out collective pitch commanded by the TCL when in APLN mode
* [ ] Reduce sensitivity of ailerons at high airspeeds
* [x] Add hard limit for Vortex Ring State, High Rate of Descent
* [ ] Add dcp-mast-torque factor
* [x] Slow down response of Roll Hold controller to make Ctrl+w less nervous and jerky
* [ ] Perhaps use gain scheduling to overcome inertia when pitch is between 2 and -2 degrees
* [ ] Add alpha or pitch limit to FBW
* [ ] Fix VTOL Yaw Rate controller
* [x] Add speed and vertical speed A/P controllers for VTOL mode
* [ ] Make TCL control the torque instead of collective of the rotors
* [ ] Modify YASim FDM so that loading ramp acts as a flight control surface
* [ ] Display warning when folding wing while /environment/wind-speed-kt > 45 knots
* [ ] Limit range of flight control surfaces
    * [x] Limit range of elevator
    * [x] Limit range of rudders
    * [ ] Limit range of flaperons
* [x] Add flash mode to navigation lights for ground operations
* [ ] Replace navigation, beacon, and landing lights with ones that look much better (from 777 perhaps?)
* [ ] Add shadow underneath the 3D model
* [x] Replace Autopilot Settings window with custom dialog
* [ ] Replace Radio window with custom dialog
* [ ] In Replay mode, sound of rotors should gradually become hearable instead of suddenly getting enabled
* [ ] Add yaw damper?
* [ ] Add overspeed and stall protection?
* [ ] Perhaps add automatic attitude stabilization (AFCS) when stick is in neutral position
* [ ] Perhaps add position (x,y) stabilization in VTOL mode when stick is in neutral position
* [x] Add radar altimeter
* [x] Add TCAS for CV-22
* [ ] Add TF/TA multimode radar for CV-22
* [ ] Modify 3D model so that wind screen wipers can be moved
* [ ] Add high resolution liveries
* [ ] Simulate ice and add de-icing system
* [ ] Add electrical system
* [ ] Add fuel system
    * [ ] Split manifold into two manifolds and connect them through a crossfeed valve
    * [x] Add JettisonConsumer and fuel jettison animation
    * [x] Add engines cut-off valves to a GUI window
* [ ] Add hydraulic system
* [ ] In cockpit, display a stall meter when nacelles are between 35 degrees and 0 degrees (horizontal)
* [ ] Add weather radar
* [x] Add support for TACAN, VOR, ILS, GPS
* [ ] Display hot exhaust gases animation below nacelles
* [ ] Display brown-out condition animation when hovering above sandy terrain
* [ ] Add cockpit to interior 3D model with fancy Canvas glass MFD's
* [ ] Add accurate V-22 checklists
* [ ] Add accurate V-22 sounds (buttons, doors, loading ramp, APU, rotors (in cockpit and outside), etc.)
* [ ] Loop "sink rate" sound for VRS warning every 5 seconds
* [ ] Add minigun to MV-22
* [x] Support aerial refueling
    * [x] Support AI > Tanker Controls
    * [x] Fix offset of probe
    * [x] Only refill left forward sponson tank when refueling
* [ ] Add aerial refueling capability for other aircraft (F-18)
* [ ] Simulate low oxygen at high altitudes, when not wearing oxygen masks:
    * [ ] Black out (permanent if too long) of pilot, co-pilot, and crew
    * [ ] Reduce sensitivity of stick and pedals input
    * [ ] When user clicks a button in the cockpit, randomly activate a nearby button instead
* [x] Make views of pilot, co-pilot, and crew depend on g force
* [ ] Add pre-flight walkaround, require user to remove several red "REMOVE BEFORE FLIGHT" flags
* [ ] Perhaps do not allow extension of landing gear at airspeed above 140 KCAS?
* [ ] Damage landing gear if descent rate > 24 fps
* [ ] Display a warning message when WOW of landing gear above 100 knots GS
* [ ] Limit mast torque to 100% without interim power and 109% with interim power
* [x] Adjust YASim FDM to work with YASIM_VERSION_32 in FlightGear 3.2
* [ ] Add missions from guide book
* [ ] Add dual control
* [ ] Use heading hold if speed is less than 25 knots, switch to turn coordinator between 25 and 45 knots
