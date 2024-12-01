%%%% Lamiah Khan, Megan Vo, and Lindsey Rodriguez
% DSP Project 5, 11/25/2024
% All resources that were used for this project will be linked! 
clc; clear; close all;

%% Project Summary/ Write-up
% This project takes the original bjruf.wav signal, and uses block
% processing to implement a speaker detection system in the frequency
% domain. This is done through equations from chapter 10, and done for both
% rectangular & Barlett windows, while implementing a heuristic method to
% create a 0-1 vector indicating the presence of speech. This project
% taught me how block processing with overlap can be used to efficiently
% analyze and prcoess long audio signals (this one had over 1.5 million
% samples) into more managable chunks. I also learned that one way to
% avoid edge effects and ensure that adjacent blocks are combined
% seamlessly is by applying the respective windows, and then performing
% inverse FFT. The speech detection algorithm works the way it does because
% it uses energy-based features (in this case, the sum of squared magnitudes 
% of the FFT coefficients) can be used to determine whether speech is 
% present or not in a segment of the audio signal. The thresholding approach 
% (energy > energyThreshold) allows for a clear distinction between speech 
% and non-speech segments. This method is computationally efficient, though 
% it may have limitations in more complex environments with noise or 
% low-volume speech. Overall, the user is able to view each block of audio
% throughout the entire audio, the audio is reconstructed clearly, and the
% vector representation of the signal matches the block processing audio. 

%% Loading the Audio File & Initializing Settings
% Loads the original audio file
[audio, fs] = audioread('bjruf.wav'); 
audio = audio(:, 1); %The system only uses first channel
N = length(audio);

% link to learn about block size and overlap:
% https://dsp.stackexchange.com/questions/59232/overlap-add-which-length-to-use.
blockSize = 1024; % Block size
hopSize = 512; % Overlap is 50%
% Energy threshold for speech detection. This value is lower because higher
% values = more sensitivity. 
energyThreshold = 0.01; 

% Define windows & initiliazing a structure to store results for each
% window
windows = {'bartlett', 'rectangular'};
windowedResults = struct();

%% Looping over window types
% For each window type, the audio is processed and reconstructed, and
% speech detection is performed.
% Loop through each window type
for wIdx = 1:length(windows)
   % Create the window
   windowType = windows{wIdx};
   switch windowType
       case 'bartlett'
           window = bartlett(blockSize);
       case 'rectangular'
           window = rectwin(blockSize);
       otherwise
           error('Unsupported window type');
   end

   %% Block Processing Setup & Loop
   % Pad the signal to ensure processing of all blocks
   audioPadded = [audio; zeros(mod(-N, hopSize), 1)];
   numBlocks = ceil(length(audioPadded) / hopSize);
   
   % Initialize storage for the reconstructed signal and speech indicator
   % for each block.
   reconstructed = zeros(size(audioPadded));
   speechIndicator = zeros(numBlocks, 1);
   
% Create a figure for intermediate visualizations
figure('Name', ['Intermediate Processing (Window: ', windowType, ')'], 'NumberTitle', 'off');

% Block processing:
% https://www.mathworks.com/matlabcentral/answers/455967-splitting-an-audio-file-into-1s-for-max-audio-files.
for r = 1:numBlocks
   % Extract block with overlap
   startIdx = (r-1)*hopSize + 1;
   endIdx = min(startIdx + blockSize - 1, length(audioPadded));
   block = audioPadded(startIdx:endIdx);
   
   % Zero-pad if necessary
   if length(block) < blockSize
       block = [block; zeros(blockSize - length(block), 1)];
   end
   
   % Each block is then windowed and transformed into the frequency domain
   % using the FFT.
   % Apply window
   windowedBlock = block .* window;
   
   % Transform to frequency domain
   Xr = fft(windowedBlock);
   
   %% Speech Detection Based on Energy
   % https://www.sciencedirect.com/science/article/abs/pii/S0965997823000042#:~:text=4.,the%20filtered%20signals%20(frames).&text=Fig.,Pre%2Dprocessing.
   % Heuristic for speech detection: Use energy in specific frequency band
   energy = sum(abs(Xr).^2) / length(Xr);
   if energy > energyThreshold
       speechIndicator(r) = 1;
   else
       speechIndicator(r) = 0;
   end
   
   %% Inverse FFT & Reconstruction
   % The block is transformed back into the time domain, and overlap-add is
   % used to reconstruct the audio signal. 
   % Transform back to time domain
   xr = real(ifft(Xr)) .* window;
   
   % Overlap-add for reconstruction
   reconstructed(startIdx:endIdx) = reconstructed(startIdx:endIdx) + xr(1:(endIdx-startIdx+1));
   
   %% Visualization of Block Processing & Results
   % Visualize intermediate steps (every 10th block for clarity). When you
   % run this program, the user will be able to see the audio block signals
   % through per both seconds and samples. 
   % https://www.mathworks.com/help/matlab/ref/drawnow.html
   if mod(r, 10) == 0
       timeBlock = (startIdx:endIdx) / fs; % Time in seconds for current block. 
        
       % Subplot 1: Original Block (in samples)
       subplot(3, 2, 1);
       plot(block);
       title(['Original Block (Block ', num2str(r), ')']);
       xlabel('Samples');
       ylabel('Amplitude');
       
       % Subplot 2: Windowed Block (in samples)
       subplot(3, 2, 2);
       plot(windowedBlock);
       title('Windowed Block');
       xlabel('Samples');
       ylabel('Amplitude');
       
       % Subplot 3: Magnitude Spectrum (in frequency bins)
       subplot(3, 2, 3);
       plot(abs(Xr));
       title('Magnitude Spectrum');
       xlabel('Frequency Bins');
       ylabel('Magnitude');
       
       % Subplot 4: Reconstructed Block (in samples)
       subplot(3, 2, 4);
       plot(xr);
       title('Reconstructed Block');
       xlabel('Samples');
       ylabel('Amplitude');
       
       % Subplot 5: Windowed Block (in seconds)
       subplot(3, 2, 5);
       plot(timeBlock, windowedBlock(1:length(timeBlock))); % Plot against time in seconds
       title('Windowed Block (Time in Seconds)');
       xlabel('Time (s)');
       ylabel('Amplitude');
       
       % Subplot 6: Reconstructed Block (in seconds)
       subplot(3, 2, 6);
       plot(timeBlock, xr(1:length(timeBlock))); % Plot against time in seconds
       title('Reconstructed Block (Time in Seconds)');
       xlabel('Time (s)');
       ylabel('Amplitude');
       
       drawnow; % Updating the plots for the current block. 
   end
end

   % Remove padding from reconstructed signal
   reconstructed = reconstructed(1:N);
   
   % Store results for the current window type
   windowedResults.(windowType).reconstructed = reconstructed;
   windowedResults.(windowType).speechIndicator = speechIndicator;
end
%% Plotting Final Results
% Plot results for each window type
time = (0:N-1) / fs;
figure('Name', 'Speech Detection Results', 'NumberTitle', 'off');
for wIdx = 1:length(windows)
   windowType = windows{wIdx};
   reconstructed = windowedResults.(windowType).reconstructed;
   speechIndicator = windowedResults.(windowType).speechIndicator;
   
   % Expand speechIndicator to match the audio length for plotting
   speechBinaryVector = repelem(speechIndicator, hopSize);
   speechBinaryVector = speechBinaryVector(1:N); % Match the signal length
   
   % Plot original signal
   subplot(length(windows), 2, 2*wIdx-1);
   plot(time, audio);
   title(['Original Audio Signal (Window: ', windowType, ')']);
   xlabel('Time (s)');
   ylabel('Amplitude');
   
   % Plot binary speech detection vector
   subplot(length(windows), 2, 2*wIdx);
   plot(time, speechBinaryVector);
   title(['Speech Detection (Window: ', windowType, ')']);
   xlabel('Time (s)');
   ylabel('Speech Presence');
end

%% Playing the Final Reconstructed Audio (both windows)
disp('Playing reconstructed audio with Bartlett window...');
sound(windowedResults.bartlett.reconstructed, fs);
pause(length(audio)/fs + 1); % pausing for playback to finish
disp('Playing reconstructed audio with Rectangular window...');
sound(windowedResults.rectangular.reconstructed, fs);
