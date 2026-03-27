#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import matplotlib.pyplot as plt

FILENAME = "motor_model_state.csv"

# Initialize arrays
n_index, n_cycle, s_dir, s_en, s_velocity, s_motor_speed = [], [], [], [], [], []

# Read from generated CSV file
with open(FILENAME, "r") as db:
    _ = db.readline()
    for l in db.readlines():
        r = [i.strip() for i in l.strip().split(",")]

        try:
            a, b, c, d, e = (int(i) for i in r[0:5])
            f = float(r[5])

            n_index.append(a)
            n_cycle.append(b)
            s_dir.append(c)
            s_en.append(d)
            s_velocity.append(e)
            s_motor_speed.append(f)
        except ValueError:
            print(" W: invalid entry detected - '%s'" % l.strip())
            continue

# Calculate signed ENABLE and signed velocity
s_signed_en = [e if d else -e for d, e in zip(s_dir, s_en)]
s_velocity = [v if v < 128 else v - 256 for v in s_velocity]

plt.plot(n_index, s_signed_en, label="Signed ENABLE")
plt.plot(n_index, s_motor_speed, label="Motor speed")
plt.plot(n_index, s_velocity, label="Measured velocity")

plt.xlabel("Cycles [1]")
plt.ylabel("Signal value [a.u.]")
plt.title("Motor model state")

plt.grid()
plt.legend()
plt.show()
