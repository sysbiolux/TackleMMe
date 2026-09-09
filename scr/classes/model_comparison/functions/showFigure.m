function newFig = showFigure(figHandle)
% Creates a copy of a figure safely.
%
% This function duplicates a figure given by its handle. It attempts
% several copy strategies in sequence: direct copyobj, children-only
% copyobj, and finally save-and-reopen via a temporary .fig file. This
% ensures compatibility with figures containing UIAxes, tables,
% clustergrams, and other complex objects.
%
% Arguments:
%   figHandle (figure): Handle of the figure to duplicate.
%
% Returns:
%   newFig (figure): Handle of the newly created figure copy.
%
% Examples:
%   ```matlab
%   newFig = showFigure(plots.funct.import);
%   ```
%
% Note:
%   The function tries three strategies in order of preference:
%   1. Direct copyobj of the entire figure
%   2. copyobj of children only into a new figure
%   3. Save to temporary .fig file and reopen

    try
        
        % tf = any(arrayfun(@(x) isa(x, 'matlab.ui.control.UIAxes'), figHandle.Children));
        % if tf 
        %     error("This is a ui figure it needs to be saved and reopened!")
        % end
        figure(copyobj(figHandle, groot));
        return;  % success, exit function
   
    catch
        try
            % if tf 
            %     error("This is a ui figure it needs to be saved and reopened!")
            % end
            children = get(figHandle, 'Children');  % get figure children
            newFig = figure;                        % create new figure
            copyobj(children, newFig);              % attempt copy
            set(newFig, 'Visible', 'on');           % ensure it shows
            return;  % success, exit function
        catch 
            % try
            %     % if tf 
            %     %     error("This is a ui figure it needs to be saved and reopened!")
            %     % end
                % Check input
                if ~ishandle(figHandle) || ~strcmp(get(figHandle,'Type'),'figure')
                    error('Input must be a valid figure handle.');
                end
                
            
                % Generate a temporary filename in the system temp folder
                tempFile = [tempname, '.fig'];
            
                try
                    % Save the figure to the temporary file
                    savefig(figHandle, tempFile);
            
                    % Open the figure as a new figure
                    newFig = openfig(tempFile, 'reuse'); % opens a new figure window
            
                    % Ensure it is visible
                    set(newFig, 'Visible', 'on');
            
                catch ME
                    % If any error occurs, delete the temp file and rethrow
                    if exist(tempFile, 'file')
                        delete(tempFile);
                    end
                    rethrow(ME);
                end
            
                % Delete the temporary file
                if exist(tempFile, 'file')
                    delete(tempFile);
                end
            % catch
            %     drawnow
            %     frame = getframe(figHandle);
            %     figure('Position', [10 10 1000 1000]) % [left bottom width height]
            %     imshow(frame.cdata)
            % end
        end
    end

end