/// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: nil -*-

// updates the status of notify
// should be called at 50hz
static void update_notify()
{
    notify.update();
}

/////////////////////////////////////////////////////////////////////////////////////////////
//	Copter LEDS by Robert Lefebvre
//	Based on the work of U4eake, Bill Sanford, Max Levine, and Oliver
//	g.copter_leds_mode controls the copter leds function via bitmath
//	Zeroeth bit turns motor leds on and off:                                00000001
//	First bit turns GPS function on and off:                                00000010
//	Second bit turns Aux function on and off:                               00000100
//	Third bit turns on Beeper (legacy Piezo) function:                      00001000
//	Fourth bit toggles between Fast Flash or Oscillate on Low Battery:      00010000		(0) does Fast Flash, (1) does Oscillate
//	Fifth bit causes motor LEDs to Nav Blink:                               00100000
//	Sixth bit causes GPS LEDs to Nav Blink:                                 01000000
//	This code is written in order to be backwards compatible with the old Motor_LEDS code
//	I hope to include at least some of the Show_LEDS code in the future
//	copter_leds_GPS_blink controls the blinking of the GPS LEDS
//	copter_leds_motor_blink controls the blinking of the motor LEDS
//	Piezo Code and beeps once on Startup to verify operation
//	Piezo Enables Tone on reaching low battery or current alert
/////////////////////////////////////////////////////////////////////////////////////////////

#define COPTER_LEDS_BITMASK_ENABLED         0x01        // bit #0
#define COPTER_LEDS_BITMASK_AUX             0x02        // bit #1
#define COPTER_LEDS_BITMASK_BEEPER          0x04        // bit #2
#define COPTER_LEDS_BITMASK_NAV_BLINK 	    0x08       	// bit #3

#if COPTER_LEDS == ENABLED
static void copter_leds_init(void)
{
    pinMode(COPTER_LED_1, OUTPUT);              //Motor LED
    pinMode(COPTER_LED_2, OUTPUT);              //Motor LED
    pinMode(COPTER_LED_3, OUTPUT);              //Motor LED
    pinMode(COPTER_LED_4, OUTPUT);              //Motor LED
    pinMode(COPTER_LED_5, OUTPUT);              //Motor or Aux LED
    pinMode(COPTER_LED_6, OUTPUT);              //Motor or Aux LED
    pinMode(COPTER_LED_7, OUTPUT);              //Motor or GPS LED
    pinMode(COPTER_LED_8, OUTPUT);              //Motor or GPS LED
    pinMode(PIEZO_PIN, OUTPUT);			//Piezo Buzzer

    if (!(g.copter_leds_mode & COPTER_LEDS_BITMASK_BEEPER)) {
        piezo_beep();
    }
}

static void update_copter_leds(void)
{
    if (g.copter_leds_mode == 0) {
        copter_leds_reset();                                        //method of reintializing LED state
    }

    if ((g.copter_leds_mode & COPTER_LEDS_BITMASK_AUX) && !ap.CH7_flag) {
        copter_leds_reset();
        return;
    }

    if (g.copter_leds_mode & COPTER_LEDS_BITMASK_ENABLED) {
        if (motors.armed()) {
            if (failsafe.battery) {
                switch (g_gps->status()) {
                    case GPS::NO_GPS:
                    case GPS::NO_FIX:
                        green_fast_blink();
                        red_off();
                        break;
                    case GPS::GPS_OK_FIX_2D:
                    case GPS::GPS_OK_FIX_3D:
                        red_fast_blink();
                        green_off();
                        break;
                }
                blue_fast_blink();
            } else {
                if (g.copter_leds_mode & COPTER_LEDS_BITMASK_NAV_BLINK && copter_leds_nav_blink > 0) {
                    switch (g_gps->status()) {
                        case GPS::GPS_OK_FIX_2D:
                        case GPS::GPS_OK_FIX_3D:
                            red_slow_blink();
                            green_off();
                            break;
                    }
                    blue_slow_blink();
                } else {
                    switch (g_gps->status()) {
                        case GPS::NO_GPS:
                        case GPS::NO_FIX:
                            green_on();
                            red_off();
                            break;
                        case GPS::GPS_OK_FIX_2D:
                        case GPS::GPS_OK_FIX_3D:
                            red_on();
                            green_off();
                            break;
                    }
                    blue_on();
                }
            }
        } else {
            switch (g_gps->status()) {
                case GPS::GPS_OK_FIX_2D:
                case GPS::GPS_OK_FIX_3D:
                    red_slow_blink();
                    green_off();
                    break;
		default:
                    green_slow_blink();
                    red_off();
                    break;
            }
            blue_slow_blink();
        }
    }
}

static void copter_leds_reset(void) {
    digitalWrite(COPTER_LED_1, COPTER_LED_OFF);
    digitalWrite(COPTER_LED_2, COPTER_LED_OFF);
    digitalWrite(COPTER_LED_3, COPTER_LED_OFF);
    digitalWrite(COPTER_LED_4, COPTER_LED_OFF);
    digitalWrite(COPTER_LED_5, COPTER_LED_OFF);
    digitalWrite(COPTER_LED_6, COPTER_LED_OFF);
    digitalWrite(COPTER_LED_7, COPTER_LED_OFF);
    digitalWrite(COPTER_LED_8, COPTER_LED_OFF);
}

static void red_fast_blink() {
    if (0 < copter_leds_motor_blink && copter_leds_motor_blink < 3) {
        red_on();
    } else if (2 < copter_leds_motor_blink && copter_leds_motor_blink < 5) {
        red_off();
    }
}

static void green_fast_blink() {
    if (0 < copter_leds_motor_blink && copter_leds_motor_blink < 3) {
        green_on();
    } else if (2 < copter_leds_motor_blink && copter_leds_motor_blink < 5) {
        green_off();
    }
}

static void blue_fast_blink() {
    copter_leds_motor_blink++;
    if (0 < copter_leds_motor_blink && copter_leds_motor_blink < 3) {
        blue_on();
    } else if (2 < copter_leds_motor_blink && copter_leds_motor_blink < 5) {
        blue_off();
    } else {
        copter_leds_motor_blink = 0;
    }
}

static void red_slow_blink() {
    if (0 < copter_leds_motor_blink && copter_leds_motor_blink < 6) {
        red_on();
    } else if (5 < copter_leds_motor_blink && copter_leds_motor_blink < 11) {
        red_off();
    }
}

static void green_slow_blink() {
    if (0 < copter_leds_motor_blink && copter_leds_motor_blink < 6) {
        green_on();
    } else if (5 < copter_leds_motor_blink && copter_leds_motor_blink < 11) {
        green_off();
    } 
}

static void blue_slow_blink() {
    copter_leds_motor_blink++;
    if (0 < copter_leds_motor_blink && copter_leds_motor_blink < 6) {
        blue_on();
    } else if (5 < copter_leds_motor_blink && copter_leds_motor_blink < 11) {
        blue_off();
    } else {
        copter_leds_motor_blink = 0;
    }
}

static void red_on() {
    digitalWrite(COPTER_LED_1, COPTER_LED_ON);
}

static void green_on() {
    digitalWrite(COPTER_LED_2, COPTER_LED_ON);
}

static void blue_on() {
    digitalWrite(COPTER_LED_3, COPTER_LED_ON);
}

static void red_off() {
    digitalWrite(COPTER_LED_1, COPTER_LED_OFF);
}

static void green_off() {
    digitalWrite(COPTER_LED_2, COPTER_LED_OFF);
}

static void blue_off() {
    digitalWrite(COPTER_LED_3, COPTER_LED_OFF);
}

void piezo_on(){
    if (g.copter_leds_mode & COPTER_LEDS_BITMASK_BEEPER) {
        digitalWrite(PIEZO_PIN,HIGH);
    }
}

void piezo_off(){
    if (g.copter_leds_mode & COPTER_LEDS_BITMASK_BEEPER) {
        digitalWrite(PIEZO_PIN,LOW);
    }
}

void piezo_beep(){                                                              // Note! This command should not be used in time sensitive loops
    if (g.copter_leds_mode & COPTER_LEDS_BITMASK_BEEPER) {
        piezo_on();
        delay(100);
        piezo_off();
    }
}

void piezo_beep_twice(){                                                        // Note! This command should not be used in time sensitive loops
    if (g.copter_leds_mode & COPTER_LEDS_BITMASK_BEEPER) {
        piezo_beep();
        delay(50);
        piezo_beep();
    }
}

#endif                  //COPTER_LEDS
