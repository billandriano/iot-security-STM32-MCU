% Define Serial Port
serialPort = serial('COM4', 'BaudRate', 9600, 'Terminator', 'LF', 'Timeout', 10);
fopen(serialPort);

% Activity and Fall Detection Parameters
fallDetectionThreshold = 2000; 
restThreshold = 1000; 
% Activity thresholds
restingThresholdUpper = 1025; % Upper limit for resting
walkingThresholdLower = 1026; % Lower limit for walking
walkingThresholdUpper = 1400; % Upper limit for walking
runningThresholdLower = 1401; % Lower limit for running


% Prepare the figure for plotting Temperature and Humidity
figure;
hold on;
xlabel('Temperature (°C)');
ylabel('Humidity (%)');
title('Temperature vs. Humidity Scatter Plot');
% Define comfort zone boundaries
comfortZoneTemp = [22, 27];
comfortZoneHum = [40, 60];
% Plot the comfort zone area
patch([comfortZoneTemp(1), comfortZoneTemp(1), comfortZoneTemp(2), comfortZoneTemp(2)], ...
      [comfortZoneHum(1), comfortZoneHum(2), comfortZoneHum(2), comfortZoneHum(1)], ...
      [0.9, 0.9, 0.9], 'LineStyle', '--', 'FaceAlpha', 0.5);

% Initialize variables
activityBuffer = {"", "", ""};
lastDisplayedActivity = "";
fallDetected = false;

try
    while true
        % Check if data is available
        if serialPort.BytesAvailable > 0
            dataLine = fgetl(serialPort); % Read a line of data
            % Parse the received data
            C = textscan(dataLine, '(%f,%f,%f,%f,%f)');
            
            % Extract accelerometer data
            x = C{1};
            y = C{2};
            z = C{3};
            % Calculate the magnitude of the acceleration vector
            g = sqrt(x.^2 + y.^2 + z.^2);
            
             
            % Fall detection logic
            if g > fallDetectionThreshold && ~fallDetected
                % Potential fall detected
                fallDetected = true;
            elseif g < restThreshold && fallDetected
                % Fall confirmed
                disp('Fall detected');
                fallDetected = false; % Reset fall detection
            end

            % Activity detection logic using thresholds
            currentActivity = "";
            if g <= restingThresholdUpper
                currentActivity = "Resting";
            elseif g >= walkingThresholdLower && g <= walkingThresholdUpper
                currentActivity = "Walking";
            elseif g >= runningThresholdLower
                currentActivity = "Running";
            end

           if ~isempty(currentActivity)
               activityBuffer = [activityBuffer(2:end), currentActivity];
                if all(strcmp(activityBuffer{1}, activityBuffer)) && ~isempty(activityBuffer{1})
                    currentConsensusActivity = activityBuffer{1};
                    if ~strcmp(currentConsensusActivity, lastDisplayedActivity) && ~isempty(currentConsensusActivity)
                        disp(['Activity: ' currentConsensusActivity]);
                        lastDisplayedActivity = currentConsensusActivity;
                    end
                end
            end
            
            % Extract and plot temperature and humidity
            temp = C{4}; % Combine integer and fractional parts
            hum = C{5}; % Combine integer and fractional parts
            scatter(temp, hum, 'filled'); % Plot current reading
            drawnow;
            
            % Print values to MATLAB Command Window (optional)
            %fprintf('X: %.2f, Y: %.2f, Z: %.2f, Temp: %.2f °C, Hum: %.2f%%\n', x, y, z, temp, hum);
        end
        pause(0.1); % Adjust the pause to control the reading frequency
    end
catch e
    disp(['Error: ', e.message]);
    fclose(serialPort);
end
