# ViconAutoProcessing_v3
Vicon Auto Processing pipeline v3 with Joey's new function fixing the segment swap and jumps
To be added:
- Ryan's auto loading config functions
- manual vs auto testing functions

## Usage
There are two main scripts to run: RunMe and RunMeCropped

- RunMe: process trials sequentially in timeseries, but processing time is too long
- RunMeCropped: Currently optimized and use Parallel method to speed up the processing

## Installation
1. Matlab: R2023b or later (supports dictionary)
2. Matlab Addons:
   - Parallel Computing Toolbox (parallel processing)
   - Signal Processing Toolbox (support Jonathan's Toolbox)
   - Instrument Control Toolbox (progress bar)
