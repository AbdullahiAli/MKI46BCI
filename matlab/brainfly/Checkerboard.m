classdef Checkerboard < handle
    % checkerBoard Class for a checkerBoard.
    
    %% Properties:
    
    properties (Constant)
        
        % The following properties of fractions of the screen width or
        % height, these properties are used to generate the actual sized at
        % object instantiation:
        relCheckerBoardWidth  = 0.1;   % The width of the checkerBoard.
        relCheckerBoardHeight = 0.1;    % The height of the checkerBoard.
        minuid=1;
        relMoveStepSize = .5;     % The maximum checkerBoard move in 1 second
           % The maximum checkerBoard move in 1 second
        %relcheckerBoardRange = [.0 .80]; % min/max checkerBoard position w.r.t. axes limits 
    end
    
    properties
        
        % The following properties hold data about the checkerBoard object:
        checkerBoardWidth;        % Actual checkerBoard width.
        checkerBoardHeight;       % Actual checkerBoard height.
        moveStepSize;       % Actual max step size.
        Xbase;              % X position of bottom left of checkerBoard.
        Ybase;              % Y position of bottom left of checkerBoard.
        hGraphic;           % Handle to ball graphics object.
        hAxes;              % Handle to axes.
        lastDrawTime;       % logs when we last re-drew the checkerBoard
        uid;                % unique identification number
        relcheckerBoardRange; % min/max checkerBoard position w.r.t. axes limits 
    end
    
    
    %% Methods:
    
    methods
        
        %==================================================================
        function obj = Checkerboard(hAxes, relcheckerBoardRange, side)
            % checkerBoard constructor:
            
            % Calculate the checkerBoard parameters:
            axesXLim     = get(hAxes,'XLim');
            
            axesYLim     = get(hAxes,'YLim');
            obj.checkerBoardWidth  = diff(axesXLim)*obj.relCheckerBoardWidth;
            obj.checkerBoardHeight = diff(axesYLim)*obj.relCheckerBoardHeight;
            switch side                
                case 'left'; % Move checkerBoard left, but keep in in bounds.
                    obj.Xbase = mean(axesXLim) - 50 -0.5*obj.checkerBoardWidth;
                    
                case 'right';  % Move checkerBoard right, but keep in in bounds.
                    obj.Xbase = mean(axesXLim) + 50 -0.5*obj.checkerBoardWidth;
            end
           
            obj.Ybase    = axesYLim(1);
            obj.relcheckerBoardRange = relcheckerBoardRange;
            
            % Make checkerBoard:
            obj.hGraphic = rectangle('curvature',[0 0]...
                ,'position',[obj.Xbase ,obj.Ybase...
                ,obj.checkerBoardWidth,obj.checkerBoardHeight],...
                'facecolor','w');
            
            % Save properties:
            obj.hAxes = hAxes;
            obj.lastDrawTime = [];
            obj.moveStepSize = obj.relMoveStepSize*diff(axesXLim);
            obj.uid = Checkerboard.getuid();
        end
        
    function move(obj,whereTo,howMuch)
            % Method to move the checkerboard.
            %
            %   obj.move(whereTo,howMuch)
            % Inputs:
            %   whereTo: one-of {'left' 'right'}
            %           the direction of movement
            %     or
            %            [float] direction position on the screen to warp checkerBoard
            %   howMuch: [float] fraction of the moveStepSize that is taken (ideally: 0<howMuch<=1).
            
            % Calculate the variable step size, taking account of draw lags
          curStepSize = obj.moveStepSize;
          if( ~isempty(howMuch) ) curStepSize=curStepSize*howMuch; end;
            if ( ~isempty(obj.lastDrawTime) ) curStepSize=curStepSize*toc(obj.lastDrawTime); end;
            axesXLim     = get(obj.hAxes,'XLim');
            if isnumeric(whereTo) % warp mode, but limit step size
              whereTo=whereTo*abs(axesXLim(2)-axesXLim(1));
              obj.Xbase = max(min(whereTo,obj.Xbase+curStepSize),obj.Xbase-curStepSize);
            else % string so step-size
              switch whereTo                
                case 'left'; % Move checkerBoard left, but keep in in bounds.
                    obj.Xbase = obj.Xbase+curStepSize;
                    
                case 'right';  % Move checkerBoard right, but keep in in bounds.
                    obj.Xbase = obj.Xbase-curStepSize;
              end
            end
         
                                % display bounds check
            axXRange = (axesXLim(2)-axesXLim(1));
            obj.Xbase = min(max(obj.Xbase,axesXLim(1)+obj.relcheckerBoardRange(1)*axXRange),...
							axesXLim(1)+obj.relcheckerBoardRange(2)*axXRange-obj.checkerBoardWidth);
            obj.Xbase
        
            % update the object properties
            pos=get(obj.hGraphic,'position');
            pos(1)=obj.Xbase;
            set(obj.hGraphic,'position',pos);
            obj.lastDrawTime=tic; % record draw time
        end
        
    end

    methods(Static)
                            
      function nuid=getuid()% only 1 checkerBoard, so always UID=1
        nuid=1;
      end

    end   
end
