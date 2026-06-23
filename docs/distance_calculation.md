# Distance Calculation Logic

This document outlines the considerations and formulas for calculating distance traveled using GT7 telemetry data.

## Units of Measure

All movement-related fields in the GT7 telemetry packet use the **Metric System**:

| Field | Type | Unit | Description |
| :--- | :--- | :--- | :--- |
| `position` | `Gt7Vector3` | **Meters** | World coordinates (X, Y, Z). |
| `velocity` | `Gt7Vector3` | **Meters/Second** | Directional velocity vector. |
| `speedMps` | `double` | **Meters/Second** | Scalar speed of the car. |

## Why `timeOfDayMs` is Unreliable
The `timeOfDayMs` field represents the **in-game world clock**. In many race scenarios, the "Time Progression" setting is accelerated (e.g., 10x, 24x). Using the delta of this field for physics or distance calculations will result in massive errors as the clock moves much faster than the actual simulation time.

## Recommended Calculation Methods

### 1. Speed × Time (The Fixed-Tick Method)
The GT7 physics engine runs at a fixed internal rate of **60Hz**. Each `packetId` increment represents exactly **1/60th of a second** (approx. 0.01667s) of simulation time.

**Formula:**
$$\Delta \text{Distance} = \text{speedMps} \times \left( \frac{\text{packetId}_{\text{new}} - \text{packetId}_{\text{old}}}{60} \right)$$

*   **Best For:** UI odometers, smooth trip-meter displays.
*   **Notes:** Reliable even with network jitter, as long as `packetId` gaps are handled correctly.

### 2. Position Delta (The Geometric Method)
Since the `position` vector is provided in meters, the Euclidean distance between two points gives the exact physical displacement.

**Formula:**
$$\text{Distance} = \sqrt{(x_2-x_1)^2 + (y_2-y_1)^2 + (z_2-z_1)^2}$$

*   **Best For:** Track mapping, sector analysis, total lap length validation.
*   **Pros:** Immune to packet loss and independent of time variables.

## Conversion Constants
*   **Mps to Kph:** `speedMps * 3.6`
*   **Meters to Kilometers:** `distance / 1000`
