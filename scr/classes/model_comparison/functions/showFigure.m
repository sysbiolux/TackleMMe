
function newFig = showFigure(figHandle)
% Creates a copy of a figure safely.
%
% This function duplicates a figure given by its handle. It attempts
% several copy strategies in sequence: direct copyobj, children-only
% copyobj, and finally save-and-reopen via a temporary .fig file. This
% ensures compatibility with figures containing UIAxes, tables,
% clustergrams, and other complex objects.
%
% The copied figure is automatically resized to fit within the screen.
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

        % Copy the entire figure
        newFig = copyobj(figHandle, groot);
        figure(newFig);

    catch
        try

            children = get(figHandle, 'Children');  % get figure children
            newFig = figure;                        % create new figure
            copyobj(children, newFig);              % attempt copy
            set(newFig, 'Visible', 'on');            % ensure it shows

        catch

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
                newFig = openfig(tempFile, 'reuse');

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

        end
    end

    % Resize the copied figure without triggering another copy
    try
        fitFigureToScreen(newFig);
    catch ME
        warning('Figure copied but resizing failed: %s', ME.message);
    end

end


function fitFigureToScreen(fig)
% Resizes and centers a figure to fit within the primary screen.
% The figure is scaled down only when necessary, preserving its
% original aspect ratio.

    % Get primary screen dimensions in pixels
    root = groot;
    oldRootUnits = get(root, 'Units');
    set(root, 'Units', 'pixels');
    cleanupRoot = onCleanup(@() set(root, 'Units', oldRootUnits));
    screen = get(root, 'ScreenSize');

    % Ensure the figure is not maximized
    set(fig, 'WindowState', 'normal');

    % Work with pixel units
    oldUnits = get(fig, 'Units');
    set(fig, 'Units', 'pixels');
    cleanupFig = onCleanup(@() set(fig, 'Units', oldUnits));
    pos = get(fig, 'Position');

    % Maximum size: 85% width and 80% height
    maxWidth  = screen(3) * 0.85;
    maxHeight = screen(4) * 0.80;

    % Reduce size only if necessary, preserving proportions
    scale = min([1, maxWidth/pos(3), maxHeight/pos(4)]);

    newWidth  = pos(3) * scale;
    newHeight = pos(4) * scale;

    % Center the figure on the primary screen
    x = screen(1) + (screen(3) - newWidth)/2;
    y = screen(2) + (screen(4) - newHeight)/2;

    set(fig, 'Position', [x, y, newWidth, newHeight]);

end
