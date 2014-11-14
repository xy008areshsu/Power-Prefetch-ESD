classdef Demand
    %DEMAND class 
    
    properties
        h_peak        % amplitude of the peak, in the unit of Watt
        h_valley      % amplitude of the low demand, in Watt
        w_peak        % duration(width) of the peak demand, in min
        w_valley      % duration of the low demand, in min
        p_peak        % period of peak, in hours
    end
    
    methods
        function self = Demand(varargin)    
            % construct the power demand in two formats: 
            % Demand(h_peak, w_peak, p_peak) or Demand(h_peak, w_peak, h_valley, w_valley)
            if nargin == 3
                self.h_peak = varargin{1};
                self.w_peak = varargin{2};
                self.p_peak = varargin{3};
                self.h_valley = 1;        % this constructor h_valley is 1 watt by default
                self.w_valley = self.p_peak * 60 - self.w_peak;
            elseif nargin == 4
                self.h_peak = varargin{1};
                self.w_peak = varargin{2};
                self.h_valley = varargin{3};
                self.w_valley = varargin{4};
                self.p_peak = 1 / self.peakFrequency();
            elseif nargin == 0
                self.h_peak = 0;
                self.w_peak = 0;
                self.h_valley = 0;
                self.w_valley = 0;
                self.p_peak = 0;
            end
                
        end
            
        
        function peak_freq = peakFrequency(self)
           peak_freq = 1 / (self.w_peak + self.w_valley); 
           peak_freq = peak_freq * 60;
        end
        
        function daily_demand = dailyDemand(self)
           daily_demand = zeros(1, 1440);   % 1440 min per day
           p_peak_min = self.p_peak * 60;
           num_of_cycles = 1440 / p_peak_min;
           for i = 0 : floor(num_of_cycles) - 1
               for j = 1 : p_peak_min
                   if j <= self.w_peak
                       daily_demand(i * p_peak_min + j) = self.h_peak;
                   else
                       daily_demand(i * p_peak_min + j) = self.h_valley;
                   end
               end
           end
           
           % add remaining power demand, in case num_of_cycles * p_peak is
           % smaller than 1440 minutes
           remain_index = floor(num_of_cycles) * p_peak_min + 1;
           if remain_index <= 1440
               for i = remain_index : 1440
                   if i - remain_index <= self.w_peak
                       daily_demand(i) = self.h_peak;
                   else
                       daily_demand(i) = self.h_valley;
                   end
               end
           end               
        end
        
    end
    
end

