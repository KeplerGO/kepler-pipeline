function [dvResultsStruct] = data_validation(dvDataObject, ...
usedDefaultValuesStruct, alerts, refTime)
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% function [dvResultsStruct] = data_validation(dvDataObject, ...
% usedDefaultValuesStruct, alerts, refTime)
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Data Validation (DV) is performed on all pipeline targets with long
% cadence multiple event threshold crossings identified in TPS. Inputs are
% converted from 0-based to 1-based indexing, and the results structure is
% initialized. Transiting planet model fitting and multiple planet search
% are conducted for all targets with TPS TCE's. Difference images are
% generated by planet candidate and target table for each target. Centroid
% and binary discrimination tests are performed for all planet candidates
% for each target. Pixel correlation tests are conducted for all planet
% candidates by target table. A statistical bootstrap is also performed for
% all planet candidates to assess the significance of the associated
% TCE. An optical ghost diagnostic test is performed for all planet
% candidates for each target. Outputs are converted back to 0-based
% indexing. A PDF report is produced for each DV target summarizing the
% model fits and results for the respective planet candidates. A one-page
% report summary is produced separately for each planet candidate. The
% model fits are performed with barycentric corrected timestamps.
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 
% Copyright 2017 United States Government as represented by the
% Administrator of the National Aeronautics and Space Administration.
% All Rights Reserved.
% 
% NASA acknowledges the SETI Institute's primary role in authoring and
% producing the Kepler Data Processing Pipeline under Cooperative
% Agreement Nos. NNA04CC63A, NNX07AD96A, NNX07AD98A, NNX11AI13A,
% NNX11AI14A, NNX13AD01A & NNX13AD16A.
% 
% This file is available under the terms of the NASA Open Source Agreement
% (NOSA). You should have received a copy of this agreement with the
% Kepler source code; see the file NASA-OPEN-SOURCE-AGREEMENT.doc.
% 
% No Warranty: THE SUBJECT SOFTWARE IS PROVIDED "AS IS" WITHOUT ANY
% WARRANTY OF ANY KIND, EITHER EXPRESSED, IMPLIED, OR STATUTORY,
% INCLUDING, BUT NOT LIMITED TO, ANY WARRANTY THAT THE SUBJECT SOFTWARE
% WILL CONFORM TO SPECIFICATIONS, ANY IMPLIED WARRANTIES OF
% MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR FREEDOM FROM
% INFRINGEMENT, ANY WARRANTY THAT THE SUBJECT SOFTWARE WILL BE ERROR
% FREE, OR ANY WARRANTY THAT DOCUMENTATION, IF PROVIDED, WILL CONFORM
% TO THE SUBJECT SOFTWARE. THIS AGREEMENT DOES NOT, IN ANY MANNER,
% CONSTITUTE AN ENDORSEMENT BY GOVERNMENT AGENCY OR ANY PRIOR RECIPIENT
% OF ANY RESULTS, RESULTING DESIGNS, HARDWARE, SOFTWARE PRODUCTS OR ANY
% OTHER APPLICATIONS RESULTING FROM USE OF THE SUBJECT SOFTWARE.
% FURTHER, GOVERNMENT AGENCY DISCLAIMS ALL WARRANTIES AND LIABILITIES
% REGARDING THIRD-PARTY SOFTWARE, IF PRESENT IN THE ORIGINAL SOFTWARE,
% AND DISTRIBUTES IT "AS IS."
% 
% Waiver and Indemnity: RECIPIENT AGREES TO WAIVE ANY AND ALL CLAIMS
% AGAINST THE UNITED STATES GOVERNMENT, ITS CONTRACTORS AND
% SUBCONTRACTORS, AS WELL AS ANY PRIOR RECIPIENT. IF RECIPIENT'S USE OF
% THE SUBJECT SOFTWARE RESULTS IN ANY LIABILITIES, DEMANDS, DAMAGES,
% EXPENSES OR LOSSES ARISING FROM SUCH USE, INCLUDING ANY DAMAGES FROM
% PRODUCTS BASED ON, OR RESULTING FROM, RECIPIENT'S USE OF THE SUBJECT
% SOFTWARE, RECIPIENT SHALL INDEMNIFY AND HOLD HARMLESS THE UNITED
% STATES GOVERNMENT, ITS CONTRACTORS AND SUBCONTRACTORS, AS WELL AS ANY
% PRIOR RECIPIENT, TO THE EXTENT PERMITTED BY LAW. RECIPIENT'S SOLE
% REMEDY FOR ANY SUCH MATTER SHALL BE THE IMMEDIATE, UNILATERAL
% TERMINATION OF THIS AGREEMENT.
%


% Get fields from the input object.
cadenceTimes = dvDataObject.dvCadenceTimes;

dvConfigurationStruct = dvDataObject.dvConfigurationStruct;
modelFitEnabled = ...
    dvConfigurationStruct.modelFitEnabled;
koiMatchingEnabled = ...
    dvConfigurationStruct.koiMatchingEnabled;
rollingBandDiagnosticsEnabled = ...
    dvConfigurationStruct.rollingBandDiagnosticsEnabled;
binaryDiscriminationTestsEnabled = ...
    dvConfigurationStruct.binaryDiscriminationTestsEnabled;
differenceImageGenerationEnabled = ...
    dvConfigurationStruct.differenceImageGenerationEnabled;
centroidTestsEnabled = ...
    dvConfigurationStruct.centroidTestsEnabled;
pixelCorrelationTestsEnabled = ...
    dvConfigurationStruct.pixelCorrelationTestsEnabled;
bootstrapEnabled = ...
    dvConfigurationStruct.bootstrapEnabled;
reportEnabled = ...
    dvConfigurationStruct.reportEnabled;
ghostDiagnosticTestsEnabled = ...
    dvConfigurationStruct.ghostDiagnosticTestsEnabled;
exceptionCatchingEnabled = ...
    dvConfigurationStruct.exceptionCatchingEnabled;

gapFillConfigurationStruct = dvDataObject.gapFillConfigurationStruct;

conditionedAncillaryDataFile = dvDataObject.conditionedAncillaryDataFile;

nTargets = length(dvDataObject.targetStruct);

% Set the cadence duration (in minutes) and append to the gap fill
% configuration structure.
cadenceDurationInMinutes = compute_cadence_duration_in_minutes(cadenceTimes);
gapFillConfigurationStruct.cadenceDurationInMinutes = cadenceDurationInMinutes;
dvDataObject.gapFillConfigurationStruct = gapFillConfigurationStruct;

% Set non target-specific randstreams.
streams = false;
fields = fieldnames(dvDataObject);

if any(strcmp('randStreamStruct', fields))
    randStreams = dvDataObject.randStreamStruct.preFitterRandStreams;
    randStreams.set_default(0);
    streams = true;
end % if

% Save legacy random sequence to mat-file because the fitter is currently
% over-sensitive. Then reset the default stream.
randn('state', 0);                                                                          %#ok<RAND>
unitRandomSequence = randn(size(cadenceTimes.gapIndicators));                                     %#ok<NASGU>
save(dvDataObject.randomDataFile, 'unitRandomSequence');

if streams
    randStreams.restore_default();
    randStreams.set_default(0);
end % if

clear cadenceTimes startTimestamps endTimestamps cadenceDurations cadenceGapIndicators

% Convert row/column coordinates and sample indices from 0-based indexing
% (Java) to 1-based indexing (Matlab).
[dvDataObject] = convert_dv_inputs_to_1_base(dvDataObject);

% Parse the data anomaly types and ensure that gap-worthy anomalies are
% gapped.
startTime = clock;
display('data_validation: gapping data anomalies...');
[dvDataObject, anomalyIndicators] = gap_data_anomalies(dvDataObject);
endTime = clock;

elapsedSeconds = etime(endTime, startTime);
disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : gap_data_anomalies completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
disp(' ');

% Correct pixel time series for all targets and target tables.
startTime = clock;
display('data_validation: correcting pixel time series...');
[dvDataObject] = correct_pixel_timeseries(dvDataObject, anomalyIndicators);
endTime = clock;

elapsedSeconds = etime(endTime, startTime);
disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : correct_pixel_timeseries completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
disp(' ');

% Normalize and quarter stitch corrected flux (as in TPS) for model
% fitting.
startTime = clock;
display('data_validation: normalizing and quarter stitching corrected flux time series...');
[normalizedFluxTimeSeriesArray] = ...
    perform_dv_flux_normalization(dvDataObject);
endTime = clock;

elapsedSeconds = etime(endTime, startTime);
disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : perform_dv_flux_normalization completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
disp(' ');

% Initialize the DV output structure.
[dvResultsStruct] = ...
    initialize_dv_output_structure(dvDataObject, ...
    normalizedFluxTimeSeriesArray, alerts);

% Create directories for placing figures and reports.
[dvResultsStruct] = ...
    create_directories_for_dv_figures(dvDataObject, dvResultsStruct);

% Perform ancillary data conditioning and save. Also clear the ancillary
% engineering data from the DV data object; the structure array can be very
% large and the raw ancillary data are never used again in DV.
startTime = clock;
key = metrics_interval_start;
display('data_validation: conditioning ancillary data...');
[conditionedAncillaryDataArray, dvResultsStruct.alerts] = ...
    synchronize_dv_ancillary_data(dvDataObject, dvResultsStruct.alerts);                   %#ok<ASGLU>
save(conditionedAncillaryDataFile, 'conditionedAncillaryDataArray');
metrics_interval_stop('dv.synchronize_dv_ancillary_data.execTimeMillis', key);
endTime = clock;

elapsedSeconds = etime(endTime, startTime);
disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : synchronize_dv_ancillary_data completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
disp(' ');

clear conditionedAncillaryDataArray

% Perform multiple planet search (if enabled) and model fitting to planet
% candidates for all targets. Compute single event statistics for
% all trial transit pulses against final residual flux time series.
if modelFitEnabled
    
    startTime = clock;
    display('data_validation: performing dv planet search and model fitting...');
    key = metrics_interval_start;
    
    [dvResultsStruct] = ...
        perform_dv_planet_search_and_model_fitting(dvDataObject, ...
        dvResultsStruct, normalizedFluxTimeSeriesArray, refTime);
    
    metrics_interval_stop('dv.perform_dv_planet_search_and_model_fitting.execTimeMillis', key);
    endTime = clock;
    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : perform_dv_planet_search_and_model_fitting completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');

end % if

clear normalizedFluxTimeSeriesArray

% Save the workspace to the intermediate data file if there are any targets
% with MES/SES ratio above the threshold for processing. Clear the
% background and motion polynomial struct arrays prior to saving.
key = metrics_interval_start;
save_dv_post_fit_workspace(dvDataObject, dvResultsStruct, ...
    usedDefaultValuesStruct);
metrics_interval_stop('dv.save_dv_post_fit_workspace.execTimeMillis', key);

% Perform KOI matching on all targets if enabled.
if koiMatchingEnabled
    
    startTime = clock;
    display('data_validation: koi matching...');
    key = metrics_interval_start;
    
    [dvResultsStruct] = ...
        perform_dv_koi_matching(dvDataObject, dvResultsStruct);
    
    metrics_interval_stop('dv.perform_dv_koi_matching.execTimeMillis', key);    
    endTime = clock;
    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : perform_dv_koi_matching completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');

else
    
    string = 'KOI matching is disabled';
    for iTarget = 1 : nTargets
        [dvResultsStruct] = add_dv_alert(dvResultsStruct, 'performDvKoiMatching', ...
            'warning', string, iTarget, ...
            dvResultsStruct.targetResultsStruct(iTarget).keplerId);
        disp(dvResultsStruct.alerts(end).message);
    end % for iTarget  
    disp(' ');
    
end % if / else

% Generate rolling band contamination diagnostics if enabled.
if rollingBandDiagnosticsEnabled
    
    startTime = clock;
    display('data_validation: generating rolling band contamination diagnostics...');
    key = metrics_interval_start;
    
    if exceptionCatchingEnabled
        try
            [dvResultsStruct] = ...
                generate_dv_rolling_band_diagnostics(dvDataObject, dvResultsStruct);
        catch exception
            string = sprintf('Unable to produce diagnostic result; caught error = %s', ...
                exception.identifier);
            for iTarget = 1 : nTargets
                [dvResultsStruct] = add_dv_alert(dvResultsStruct, ...
                    'generateDvRollingBandDiagnostics', ...
                    'warning', string, iTarget, ...
                    dvResultsStruct.targetResultsStruct(iTarget).keplerId);
                disp(dvResultsStruct.alerts(end).message);
            end % for iTarget
            save exception_rb.mat exception
        end % try/catch
    else
        [dvResultsStruct] = ...
            generate_dv_rolling_band_diagnostics(dvDataObject, dvResultsStruct);
    end % if /else
    
    metrics_interval_stop('dv.generate_dv_rolling_band_diagnostics.execTimeMillis', key);    
    endTime = clock;
    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : generate_dv_rolling_band_diagnostics completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');

else
    
    string = 'Rolling band contamination diagnostics are disabled';
    for iTarget = 1 : nTargets
        [dvResultsStruct] = add_dv_alert(dvResultsStruct, 'generateDvRollingBandDiagnostics', ...
            'warning', string, iTarget, ...
            dvResultsStruct.targetResultsStruct(iTarget).keplerId);
        disp(dvResultsStruct.alerts(end).message);
    end % for iTarget
    disp(' ');
    
end % if / else

% Perform the binary discrimination test on all targets if the test is 
% enabled.
if binaryDiscriminationTestsEnabled
    
    startTime = clock;
    display('data_validation: performing dv binary discrimination tests...');
    key = metrics_interval_start;
    
    if exceptionCatchingEnabled
        try
            [dvResultsStruct] = ...
                perform_dv_binary_discrimination_tests(dvDataObject, dvResultsStruct);
        catch exception
            string = sprintf('Unable to produce diagnostic result; caught error = %s', ...
                exception.identifier);
            for iTarget = 1 : nTargets
                [dvResultsStruct] = add_dv_alert(dvResultsStruct, ...
                    'performDvBinaryDiscrimination', ...
                    'warning', string, iTarget, ...
                    dvResultsStruct.targetResultsStruct(iTarget).keplerId);
                disp(dvResultsStruct.alerts(end).message);
            end % for iTarget
            save exception_eb.mat exception
        end % try/catch
    else
        [dvResultsStruct] = ...
            perform_dv_binary_discrimination_tests(dvDataObject, dvResultsStruct);
    end % if /else
    
    metrics_interval_stop('dv.perform_dv_binary_discrimination_tests.execTimeMillis', key);    
    endTime = clock;
    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : perform_dv_binary_discrimination_tests completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');

else
    
    string = 'Eclipsing binary discrimination tests are disabled';
    for iTarget = 1 : nTargets
        [dvResultsStruct] = add_dv_alert(dvResultsStruct, 'performDvBinaryDiscrimination', ...
            'warning', string, iTarget, ...
            dvResultsStruct.targetResultsStruct(iTarget).keplerId);
        disp(dvResultsStruct.alerts(end).message);
    end % for iTarget
    disp(' ');
    
end % if / else

% Generate difference images quarter by quarter for the DV reports if
% enabled.
if differenceImageGenerationEnabled
    
    % Generate the difference images.
    startTime = clock;
    display('data_validation: generating dv difference images...');
    key = metrics_interval_start;
    
    if exceptionCatchingEnabled
        try
            [dvResultsStruct] = ...
                generate_dv_difference_images(dvDataObject, dvResultsStruct);
        catch exception
            string = sprintf('Unable to produce diagnostic result; caught error = %s', ...
                exception.identifier);
            for iTarget = 1 : nTargets
                [dvResultsStruct] = add_dv_alert(dvResultsStruct, ...
                    'generateDvDifferenceImages', ...
                    'warning', string, iTarget, ...
                    dvResultsStruct.targetResultsStruct(iTarget).keplerId);
                disp(dvResultsStruct.alerts(end).message);
            end % for iTarget
            save exception_di.mat exception
        end % try/catch
    else
        [dvResultsStruct] = ...
            generate_dv_difference_images(dvDataObject, dvResultsStruct);
    end % if /else
    
    metrics_interval_stop('dv.generate_dv_difference_images.execTimeMillis', key);
    endTime = clock;
    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : generate_dv_difference_images completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');

else
    
    string = 'Difference image generation is disabled';
    for iTarget = 1 : nTargets
        [dvResultsStruct] = add_dv_alert(dvResultsStruct, 'generateDvDifferenceImages', ...
            'warning', string, iTarget, ...
            dvResultsStruct.targetResultsStruct(iTarget).keplerId);
        disp(dvResultsStruct.alerts(end).message);
    end % for iTarget    
    disp(' ');
    
end % if / else

% Perform the bootstrap for each planet candidate (for all targets) on the
% single event statistics for the final residual flux time series.
if bootstrapEnabled
    
    startTime = clock;
    display('data_validation: performing dv bootstrap...');
    key = metrics_interval_start;
    
    if exceptionCatchingEnabled
        try
            [dvResultsStruct] = ...
                perform_dv_bootstrap(dvDataObject, dvResultsStruct);
        catch exception
            string = sprintf('Unable to produce diagnostic result; caught error = %s', ...
                exception.identifier);
            for iTarget = 1 : nTargets
                [dvResultsStruct] = add_dv_alert(dvResultsStruct, ...
                    'bootstrap', ...
                    'warning', string, iTarget, ...
                    dvResultsStruct.targetResultsStruct(iTarget).keplerId);
                disp(dvResultsStruct.alerts(end).message);
            end % for iTarget
            save exception_bs.mat exception
        end % try/catch
    else
        [dvResultsStruct] = ...
            perform_dv_bootstrap(dvDataObject, dvResultsStruct);
    end % if /else
    
    metrics_interval_stop('dv.perform_dv_bootstrap.execTimeMillis', key);    
    endTime = clock;
    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : perform_dv_bootstrap completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');
 
else
    
    string = 'Statistical bootstrap is disabled';
    for iTarget = 1 : nTargets
        [dvResultsStruct] = add_dv_alert(dvResultsStruct, 'bootstrap', ...
            'warning', string, iTarget, ...
            dvResultsStruct.targetResultsStruct(iTarget).keplerId);
        disp(dvResultsStruct.alerts(end).message);
    end % for iTarget   
    disp(' ');
    
end % if / else

% Perform the centroid test on all targets if the test is enabled.
if centroidTestsEnabled

    % Perform the tests.
    startTime = clock;
    display('data_validation: performing dv centroid tests...');
    key = metrics_interval_start;
    
    if exceptionCatchingEnabled
        try
            [dvResultsStruct] = ...
                perform_dv_centroid_tests(dvDataObject, dvResultsStruct);
        catch exception
            string = sprintf('Unable to produce diagnostic result; caught error = %s', ...
                exception.identifier);
            for iTarget = 1 : nTargets
                [dvResultsStruct] = add_dv_alert(dvResultsStruct, ...
                    'Centroid test', ...
                    'warning', string, iTarget, ...
                    dvResultsStruct.targetResultsStruct(iTarget).keplerId);
                disp(dvResultsStruct.alerts(end).message);
            end % for iTarget
            save exception_cm.mat exception
        end % try/catch
    else
        [dvResultsStruct] = ...
            perform_dv_centroid_tests(dvDataObject, dvResultsStruct);
    end % if /else
    
    metrics_interval_stop('dv.perform_dv_centroid_tests.execTimeMillis', key);
    endTime = clock;
    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : perform_dv_centroid_tests completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');

else
    
    string = 'Centroid motion test is disabled';
    for iTarget = 1 : nTargets
        [dvResultsStruct] = add_dv_alert(dvResultsStruct, 'Centroid test', ...
            'warning', string, iTarget, ...
            dvResultsStruct.targetResultsStruct(iTarget).keplerId);
        disp(dvResultsStruct.alerts(end).message);
    end % for iTarget  
    disp(' ');
    
end % if / else

% Perform the ghost diagnostic tests on all targets if the test is enabled.
if ghostDiagnosticTestsEnabled

    % Perform the tests.
    startTime = clock;
    display('data_validation: performing dv ghost diagnostic tests...');
    key = metrics_interval_start;
    
    if exceptionCatchingEnabled
        try
            [dvResultsStruct] = ...
                perform_dv_ghost_diagnostic_tests(dvDataObject, dvResultsStruct);
        catch exception
            string = sprintf('Unable to produce diagnostic result; caught error = %s', ...
                exception.identifier);
            for iTarget = 1 : nTargets
                [dvResultsStruct] = add_dv_alert(dvResultsStruct, ...
                    'Ghost diagnostic tests', ...
                    'warning', string, iTarget, ...
                    dvResultsStruct.targetResultsStruct(iTarget).keplerId);
                disp(dvResultsStruct.alerts(end).message);
            end % for iTarget
            save exception_gd.mat exception
        end % try/catch
    else
        [dvResultsStruct] = ...
            perform_dv_ghost_diagnostic_tests(dvDataObject, dvResultsStruct);
    end % if /else
    
    metrics_interval_stop('dv.perform_dv_ghost_diagnostic_tests.execTimeMillis', key);
    endTime = clock;
    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : perform_dv_ghost_diagnostic_tests completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');

else
    
    string = 'Ghost diagnostic tests are disabled';
    for iTarget = 1 : nTargets
        [dvResultsStruct] = add_dv_alert(dvResultsStruct, 'Ghost diagnostic tests', ...
            'warning', string, iTarget, ...
            dvResultsStruct.targetResultsStruct(iTarget).keplerId);
        disp(dvResultsStruct.alerts(end).message);
    end % for iTarget
    disp(' ');
    
end % if / else

% Perform the pixel correlation tests quarter by quarter on all targets if
% the test is enabled.
if pixelCorrelationTestsEnabled

    % Perform the tests.
    startTime = clock;
    display('data_validation: performing dv pixel correlation tests...');
    key = metrics_interval_start;
    
    if exceptionCatchingEnabled
        try
            [dvResultsStruct] = ...
                perform_dv_pixel_correlation_tests(dvDataObject, dvResultsStruct);
        catch exception
            string = sprintf('Unable to produce diagnostic result; caught error = %s', ...
                exception.identifier);
            for iTarget = 1 : nTargets
                [dvResultsStruct] = add_dv_alert(dvResultsStruct, ...
                    'Pixel correlation test', ...
                    'warning', string, iTarget, ...
                    dvResultsStruct.targetResultsStruct(iTarget).keplerId);
                disp(dvResultsStruct.alerts(end).message);
            end % for iTarget
            save exception_pc.mat exception
        end % try/catch
    else
        [dvResultsStruct] = ...
            perform_dv_pixel_correlation_tests(dvDataObject, dvResultsStruct);
    end % if /else
    
    metrics_interval_stop('dv.perform_dv_pixel_correlation_tests.execTimeMillis', key);
    endTime = clock;
    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : perform_dv_pixel_correlation_tests completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');
    
else
    
    string = 'Pixel correlation test is disabled';   
    for iTarget = 1 : nTargets
        [dvResultsStruct] = add_dv_alert(dvResultsStruct, 'Pixel correlation test', ...
            'warning', string, iTarget, ...
            dvResultsStruct.targetResultsStruct(iTarget).keplerId);
        disp(dvResultsStruct.alerts(end).message);
    end % for iTarget  
    disp(' ');
    
end % if / else

% Generate a pdf report for each target and a summary report (fig, png and
% eps) for each planet candidate.
if reportEnabled
    
    startTime = clock;
    display('data_validation: generating dv reports...');
    key = metrics_interval_start;
    [dvResultsStruct] = dv_generate_reports(dvDataObject, dvResultsStruct, ...
        usedDefaultValuesStruct);
    disp(' ');
    
    display('data_validation: generating dv report summaries...');
    [dvResultsStruct] = dv_generate_report_summaries(dvDataObject, dvResultsStruct, ...
        usedDefaultValuesStruct);
    metrics_interval_stop('dv.dv_generate_reports.execTimeMillis', key);    
    endTime = clock;
    disp(' ');

    elapsedSeconds = etime(endTime, startTime);
    disp(['refTime ' num2str(etime(clock, refTime), '%6.2f') ' seconds : dv_generate_reports and dv_generate_report_summaries completed in ' num2str(elapsedSeconds, '%6.2f') ' seconds']);
    disp(' ');
    
end % if

% Save DV output matrix.
save_dv_output_matrix(dvDataObject, dvResultsStruct);

% Remove pixel data mat-files for all targets and target tables.
remove_pixel_data_matfiles(dvDataObject);

% Convert row/column outputs from Matlab 1-base to Java 0-base.
[dvResultsStruct] = convert_dv_outputs_to_0_base(dvResultsStruct);

% Replace KIC parameter NaN's to prevent DV Java crash.
[dvResultsStruct] = replace_kic_parameter_nans(dvResultsStruct);

% Restore the default randstreams.
if streams
    randStreams.restore_default();
end % if

% Return.
return
