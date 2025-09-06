function guitar_trainer()
    chords = {'A minor', 'D minor', 'E minor', 'D major', 'C major', ...
              'G major', 'A7', 'B minor', 'A major', 'B major'};

    chord_freqs = {
        [110, 220, 261.63, 329.63, 440, 659.25], 
        [146.83, 293.66, 349.23, 392, 523.25, 587.33], 
        [82.41, 164.81, 196, 246.94, 329.63, 392],  
        [146.83, 293.66, 349.23, 440, 587.33, 659.25], 
        [82.41, 110, 130.81, 261.63, 329.63, 392], 
        [82.41, 110, 196, 246.94, 392, 493.88],
        [110, 220, 261.63, 293.66, 329.63, 440], 
        [110, 220, 246.94, 293.66, 349.23, 493.88],
        [110, 220, 261.63, 329.63, 440, 523.25], 
        [110, 246.94, 293.66, 329.63, 392, 493.88] 
    };
    [selection, ok] = listdlg('ListString', chords, ...
                               'PromptString', 'Select a chord to practice:', ...
                               'SelectionMode', 'single');
    
    if ok
        selected_chord = chords{selection};
        expected_freqs = chord_freqs{selection};
        display_chord_info(selected_chord);
        record_and_check_chord(selected_chord, expected_freqs);
    end
end

function display_chord_info(chord)
    fprintf('Instructions for playing %s:\n', chord);
end

function record_and_check_chord(chord, expected_freqs)
    fs = 44100; 
    recObj = audiorecorder(fs, 16, 1); 
    
    disp('Recording... Play the chord now.');
    recordblocking(recObj, 2); 
    disp('Recording stopped.');
    
    audioData = getaudiodata(recObj);
    
    audioData_filtered = bandpass_filter(audioData, fs);
    
    if check_chord(audioData_filtered, expected_freqs, fs)
        disp('Correct chord played!');
    else
        disp('Incorrect chord. Try again.');
        record_and_check_chord(chord, expected_freqs);
    end
end

function audioData_filtered = bandpass_filter(audioData, fs)
    lowCutoff = 80;  
    highCutoff = 1000;
    
    [b, a] = butter(2, [lowCutoff, highCutoff] / (fs / 2), 'bandpass');
    
    audioData_filtered = filter(b, a, audioData);
end

function is_correct = check_chord(audioData, expected_freqs, fs)
    audioData = audioData / max(abs(audioData));
    
    n = length(audioData);
    Y = fft(audioData);
    P2 = abs(Y/n); 
    P1 = P2(1:n/2+1); 
    P1(2:end-1) = 2*P1(2:end-1);

    f = fs*(0:(n/2))/n;
    
    maxAmplitude = max(P1);
    minPeakHeight = 0.3 * maxAmplitude;
    [peaks, locs] = findpeaks(P1, 'MinPeakDistance', 5, 'MinPeakHeight', minPeakHeight);
    fundamental_freqs = f(locs(locs < 1000));
    
    is_correct = false;
    
    if isempty(fundamental_freqs)
        disp('No significant peaks found in the audio data. Please try playing the chord more clearly.');
        return;
    end
    
    tolerance = 5;
    match_count = 0;
    
    for freq = expected_freqs
        if any(abs(fundamental_freqs - freq) < tolerance)
            match_count = match_count + 1;
        end
    end
    
    if match_count >= length(expected_freqs) * 0.67
        is_correct = true;
    else
        disp('Not enough matching frequencies. Please try again.');
    end
end
