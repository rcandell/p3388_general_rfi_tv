# RFI Generation (p3388_general_rfi_tv) 
This project provides MATLAB code for generating generic radio frequency interference (RFI) test vectors at any frequency. These vectors enable the simulation or replication of interference in laboratory settings using equipment that upconverts baseband signals to a desired center frequency. While not intended to replace commercial test equipment, the code offers potential for integration into such systems to support the IEEE 3388 wireless test standard.

## How to use this code

### General Workflow
The process for using this code is straightfoward.  It entails developing a J specification (or JSPEC) in JSON which specify properties of reactors used to .  Tools are provided to create this JSON file from information in an Excel spreadsheet.  The process is described in the diagram below.

```mermaid
graph TD;
    JSTEMP[JSPEC Template] --> MKJSPEC([makejspec]);
    REACSPEC[Reactor Specs] --> MKJSPEC;
    MKJSPEC --> JSPECFILE[reactors_autogen.json]
    JSPECFILE --> MKSPGM([makespectrogram])
    MKSPGM --> SPGMFILE[Spectrogram File]
    SPGMFILE --> MKTS([maketimesignal])
    JSPECFILE --> MKTS
    MKTS --> TSFILE[Time Signal File]
    TSFILE --> TESTEQ[Test equipment]
```

### What is a JSPEC Reactor?
The notation J is used commonly to denote an interference or jamming signal.  As such, a "Jspec" is simply a specification for interference, and in this case, radio frequency interference.  The Jspec provides information in the JSON format regarding frequency, time, and amplitude characteristics of the interference.  The goal is to produce a perspective over time, frequency, and amplitude of an interference scenario as easily as possible.  A reactor is a state machine construct that allows for the modeling of the ON/OFF behavior of the signal using a Gilbert-Elliot probability model.  The user must provide the desired transition probabilities.  Time, amplitude, and freqency properties allow the user to create scenarios to be applied.

### Creating a JSPEC
A Jspec is created with two components:
+ Jspec header template, and
+ Jspec reactor specification file.

To produce a Jspec autogenerated file, in MATLAB call the following command.
```
makejspec
```

### Creating a Spectrogram Reactor Specification
A Jspec reactor specification file is a spreadsheet with the following information.  Each reactor is specified as a row with the columns specifying the properties of each.

The properties for a Jspec reactor are as follows:

+ **Name** A name for the reactor.  This does not need to be unique.
+ **type** Unused at this time
+ **centerbin** The centroid frequency bin this reactor.  The centerbin should be viewed as a bin in a two-side FFT.
+ **ge_prob_11** Gilbert Elliot transition probability from OFF to OFF
+ **ge_prob_12** Gilbert Elliot transition probability from OFF to ON
+ **ge_prob_21** Gilbert Elliot transition probability from ON to OFF
+ **ge_prob_22** Gilbert Elliot transition probability from ON to ON
+ **bw_distr_type** Determines the number of bins occupied at each reactor iteration. May be "normal" or "flat".  
+ **bw_distr_mean** Average number of bins occupied relative to center bin.
+ **bw_distr_std** Standard deviation of bins occupied relative to center bin.
+ **pwr_distr_type** Distribution of interference power.  Only normal is supported at this time.
+ **pwr_distr_mean** Average interference power
+ **pwr_distr_std** Standard deviation
+ **pwr_shaping** Boolean 0/1 if power is shaped normal across frequency
+ **pwr_shaping_std** If pwr_shaping is 1, the standard deviation of normal power distribution across frequency

### Converting the Jspec to a spectrogram
An RFI scenario is essentially a time,frequency, and amplitude scenario where interference is specified in discrete time intervals.  The following information is available in the Jspec template.  This may be modified in the template or in the automatically generated JSON file `reactors_autogen.json`.  

```
  "spectrogram": {
    "Duration_s": 1,                                         # duration of the scenario to be produced
    "NFreqBins": 1025,                                       # Number of bins in the two-sided FFT
    "WindowSize_s": 0.001,                                   # Windows duration of each spectrogram entry
    "NoiseFloorPower_dB": -100,                              # power of the noise floor relative to 0 dB
    "PathToOutputSpectrogram": "./outputs/spectrogram.csv"   # output file location for the spectrogram
  }
```
To produce the spectrogram scenario, call the following in MATLAB.
```
makespectrogram
```
This will produce a spectrogram output file in the `outputs` folder.  The spectrogram is stored as a CSV file.

### Converting the Spectrogram to a Time Signal
Once a spectrogram is ready.  It can be converted to a time domain signal.  This signal is produced using an Inverse FFT process. The following properties are available in the ifft portion of the Jspec.
```
  "ifft": {
    "DurationPerChunk_s": -1,                               # duration per time window.  A negative value indicates to used the original window size of the FFT
    "StartingSampleRate_Hz": 10e6,                          # the desired baseband sample rate
    "UpsampleRate": 1,                                      # if desired, an upsample rate.  This is usually not requried
    "ApplyRandomPhaseOffset": true,                         # boolean if a block phase offset should be applied
    "PhaseNoise_rads": 0.1,                                 # phase noise applied
    "PathToOutputTimeSignal": "./outputs/timesignal.csv"    # output file location for the time domain signal
  }
```

To convert the spectrogram to a time domain signal, call the maketimesignal script.  
```
maketimesignal
```

The final time domain signal output file is stored as a text file as complex values, the first column being the real part, and the second column being the imaginary part.  This file can great very large depending on the resulting sample rate to the file.

### View resulting files
Utilities are provided for viewing the intermediary and final outputs as MATLAB scripts.  The scripts are:

+ testshowspectrogram
+ testshowtimesignal
+ testjsondecode

These tools are self-explanatory for the user.




## The IEEE 3388 Standard
The IEEE 3388 Standard, titled "Standard for the Performance Assessment of Industrial Wireless Systems," is used to establish a framework for evaluating the performance of wireless networks in industrial and mission-critical settings where reliability and latency are critical. It is protocol-agnostic, meaning it applies to all wireless protocols used in industrial environments, such as manufacturing, power generation, precision sensing, and closed-loop control systems.

The standard serves the following key purposes:

+ Defines a Functional Model: It provides a model for radio frequency (RF) performance degradation factors, known as "aggressors" (e.g., interference, competing traffic, and multi-path propagation), that impact wireless signal quality.
+ Reference Test Architecture: It outlines a standardized test methodology and architecture for assessing the performance of industrial wireless systems.
+ Transparent Assessment Process: It specifies processes for test planning, evaluation, and reporting to ensure transparency and consistency.
+ Industry-Specific Profiles: It includes instructions for creating tailored profiles to customize the assessment process for specific industries, applications, or scenarios.
+ Enhances Reliability: By enabling standardized testing prior to deployment, it helps ensure wireless systems are reliable for mission-critical applications, such as those involving sensors, actuators, and control systems.

The 3388 standard does not cover hardware implementation details, signal processing algorithms, or the internal workings of the wireless networks being tested. It aims to advance the adoption of wireless technology as a reliable communication mode in industrial environments by addressing both physical and electromagnetic forms of signal degradation.

+ The standard may be found here at the IEEE P3388 landing page [here](https://standards.ieee.org/ieee/3388/11516/). 
+ Information on the working group may be found [here](https://sagroups.ieee.org/p3388/)




