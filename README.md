# Medium Transmission Line Calculator

This MATLAB App Designer project provides a graphical user interface (GUI) to calculate various parameters of medium transmission lines using both T-model and Π-model. It also draws phasor diagrams and generates a comparative table of results.

![App Screenshot](https://raw.githubusercontent.com/Eypan439/Medium_Transmission_Line_Calculator/refs/heads/main/Ekran%20g%C3%B6r%C3%BCnt%C3%BCs%C3%BC%202025-05-13%20231212.png)

## Features
- **Graphical User Interface (GUI)**:
  - Input fields for transmission line parameters.
  - Output table for calculated parameters.
  - Interactive phasor diagram visualization.

- **Models Supported**:
  - T-model and Π-model for medium transmission lines.

- **Calculations**:
  - Voltage regulation
  - Efficiency
  - Active and reactive power
  - Power factor

- **Phasor Diagram**:
  - Visualizes voltage and current phasors for both models.

## How to Use
1. Clone this repository:
   ```bash
   git clone https://github.com/<your-username>/Medium-Transmission-Line-Calculator.git
   ```
2. Open the `Medium_Transmission_Line_Calculator.mlapp` file in MATLAB App Designer.
3. Run the application and input the required parameters.
4. Click the **Calculate** button to view the results and phasor diagrams.

## Requirements
- MATLAB R2023a or later
- App Designer toolbox

## Input Parameters
- **Sending end 3ϕ voltage (kV)**
- **Sending end current (A)**
- **Per unit length resistance (Ω/km)**
- **Per unit length inductance (mH/km)**
- **Per unit length capacitance (μF/km)**
- **Per unit length conductance (μS/km)**
- **System frequency (Hz)**
- **Transmission line length (km)**
- **Sending end power factor**

## Output
- Calculated results for both T-model and Π-model
- Phasor diagrams for voltage and current

## Author
- **Eyyüphan ÇAKIR**
- Student ID: 242124019
