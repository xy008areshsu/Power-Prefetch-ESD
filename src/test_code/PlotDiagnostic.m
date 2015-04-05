classdef PlotDiagnostic < matlab.unittest.diagnostics.Diagnostic
    % Test suite to display graphs. If nothing is wrong, it will show the
    % graph. Otherwise it will show error messages.
    
    properties
        Title
        Actual
        Expected
        X_axis
        Y_axis
    end

    methods
        function diag = PlotDiagnostic(title, actual, expected, x_axis, y_axis)
            diag.Title = title;
            diag.Actual = actual;
            diag.Expected = expected;
            diag.X_axis = x_axis;
            diag.Y_axis = y_axis;
        end
        
        function diagnose(diag)
            diag.DiagnosticResult = sprintf('Generating plot with title "%s"', diag.Title);
            figure
            plot(1:numel(diag.Actual), diag.Actual, 'r', 1:numel(diag.Expected), diag.Expected','b', 'LineWidth', 1);
            xlabel(diag.X_axis);
            ylabel(diag.Y_axis);
            title(diag.Title);
            grid
            legend('Actual Values', 'Expected Values');
        end
    end
end
