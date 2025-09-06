clear;
clc;
fs = 44100;           
frameSize = 16384;   
tuning_threshold = 1;   
zeroPaddingFactor = 4;   
guitar_frequencies = [82.41, 110.00, 146.83, 196.00, 246.94, 329.63];
string_names = {'Low E (82.41 Hz)', 'A (110.00 Hz)', 'D (146.83 Hz)', ...
               'G (196.00 Hz)', 'B (246.94 Hz)', 'High E (329.63 Hz)', 'Exit Program'};
while true
    disp('Select the string you want to tune:');
    selection = menu('Choose String to Tune', string_names);
    if selection == 0 || selection == length(string_names)
        disp('Exiting tuner. Goodbye!');
        break;
    end 
    selected_string = string_names{selection};
    target_frequency = guitar_frequencies(selection);
    fprintf('You selected: %s\n', selected_string);
    try
        audioReader = audioDeviceReader('SampleRate', fs, ...
                                        'SamplesPerFrame', frameSize, ...
                                        'NumChannels', 1);
    catch ME
        disp(['Error initializing audio device: ', ME.message]);
        continue; 
    end
    
    disp('Starting tuner. Press Ctrl+C to stop manually.');
    
    while true
        try
            audioFrame = audioReader();
            
            audioFrame = audioFrame - mean(audioFrame);
            
            window = hann(length(audioFrame));
            windowedFrame = audioFrame .* window;
            
            windowedFrame_padded = [windowedFrame; zeros(length(windowedFrame)*(zeroPaddingFactor-1),1)];
            
            Y = fft(windowedFrame_padded);
            P2 = abs(Y / length(windowedFrame_padded));
            P1 = P2(1:floor(length(Y)/2)+1);
            P1(2:end-1) = 2 * P1(2:end-1);
            f = fs * (0:(floor(length(Y)/2))) / length(Y);
            
            [peakValue, peakIndex] = max(P1);
            dominant_freq = f(peakIndex);
            
            if peakIndex > 1 && peakIndex < length(P1)
                alpha = P1(peakIndex-1);
                beta = P1(peakIndex);
                gamma = P1(peakIndex+1);
                p = 0.5 * (alpha - gamma) / (alpha - 2*beta + gamma);
                dominant_freq = f(peakIndex) + p * (f(2) - f(1));
            end
            
            harmonic_num = round(dominant_freq / target_frequency);
            if harmonic_num >= 2 && abs(dominant_freq - harmonic_num * target_frequency) < tuning_threshold * 2
                estimated_fundamental = dominant_freq / harmonic_num;
                dominant_freq = estimated_fundamental;
            end
            
            frequency_difference = dominant_freq - target_frequency;
            
            if abs(frequency_difference) <= tuning_threshold
                tuning_status = 'In tune!';
                color = 'g';
            elseif frequency_difference > 0
                tuning_status = sprintf('Sharp by %.2f Hz', frequency_difference);
                color = 'r';
            else
                tuning_status = sprintf('Flat by %.2f Hz', abs(frequency_difference));
                color = 'b';
            end
            
            if strcmp(color, 'g')
                fprintf('\033[32mDetected Frequency: %.2f Hz - %s\033[0m\n', dominant_freq, tuning_status);
            elseif strcmp(color, 'r')
                fprintf('\033[31mDetected Frequency: %.2f Hz - %s\033[0m\n', dominant_freq, tuning_status);
            else
                fprintf('\033[34mDetected Frequency: %.2f Hz - %s\033[0m\n', dominant_freq, tuning_status);
            end
            
            if strcmp(tuning_status, 'In tune!')
                disp('String is in tune. Returning to main menu.');
                break; 
            end            
            pause(0.3);            
        catch ME
            disp(['Error: ', ME.message]);
            break; 
        end
    end    
    release(audioReader);   
end
