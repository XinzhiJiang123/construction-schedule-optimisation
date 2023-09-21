# construction-schedule-optimisation

## Overview

This software tool aims to aid the automation and optimisation the scheduling of contruction activities. It reads information from 3D building model(s), takes in user preferences, and produces automatically as output optimised schedule(s) for the building.

![schedule opt](https://github.com/XinzhiJiang123/construction-schedule-optimisation/assets/68220328/c558fb21-bb34-4258-a261-4fe6a0981dd5)

This tool is developed under a MSc thesis project in Delft University of Technology, titled:

_Construction schedule optimisation: Optimisation of BIM-based, component-level construction schedule for building structural and MEP systems considering parallel working zones_

This tool is a technical implementation of a conceptual framework described in the report, covering the topics of activity sequencing, clustering & splitting of activities, and multi-objective optimisation.

The full report can be found at TU Delft Repository: http://resolver.tudelft.nl/uuid:eeed7784-9632-4ecb-932e-74f49d5aea99


***********

## Functionality and implementation
**Functionality:**

1. Read component information from BIM (.ifc) file into Excel spreadsheet

2. Map the components with their activity, duration, cost and resource data in the database

3. Formulate, solve and display the result of the multi-objective optimisation (MOO) problem, after taking user preferences

4. Write the schedule into Excel and then Microsoft Project

**This tool consists of three parts:**

1. Excel add-in

2. MATLAB standalone executable programme

3. Excel macro workbook

Link to a video demo: https://drive.google.com/drive/folders/1grtSF4BfzHDR2HcSaCImVrTkMqrH_HeR?usp=share_link

***********

## Wiki

- Overview
- Installation guide
- HowTo's: instruction on how to use the tool, with a real-life project step-by-step


