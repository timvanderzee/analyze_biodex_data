function varargout = newfig(varargin)
% NEWFIG MATLAB code for newfig.fig
%      NEWFIG, by itself, creates a new NEWFIG or raises the existing
%      singleton*.
%
%      H = NEWFIG returns the handle to a new NEWFIG or the handle to
%      the existing singleton*.
%
%      NEWFIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NEWFIG.M with the given input arguments.
%
%      NEWFIG('Property','Value',...) creates a new NEWFIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before newfig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to newfig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help newfig

% Last Modified by GUIDE v2.5 25-Nov-2025 08:33:54

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @newfig_OpeningFcn, ...
                   'gui_OutputFcn',  @newfig_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before newfig is made visible.
function newfig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to newfig (see VARARGIN)

% Choose default command line output for newfig
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes newfig wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = newfig_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

Client.LoadViconDataStreamSDK();
% Program options
HostName = 'localhost:801';
% Make a new client
MyClient = Client();
while ~MyClient.IsConnected().Connected
    % Direct connection
    MyClient.Connect( HostName );
end

stop_time = 10; 
y_min =  str2double(handles.ymin.String);
y_plus = str2double(handles.ymax.String);
ylim([y_min y_plus]);
set(gca, 'ytick', (y_min:5:y_plus))
xlim([0 stop_time]);

MyClient.EnableDeviceData(); % Enable ForcePlate/EMG... and other analog device data in the Vicon DataStream.
MyClient.SetStreamMode( StreamMode.ClientPull );

%fixing the scale at 128
%scaling_voltage = 17338*2;
%fixing the scale at 256
% scaling_voltage = 17338*4;
% scaling_voltage = 77746;
% scaling_voltage = 1/2.5226e-06 * 10;
scaling_voltage = str2double(handles.scale_factor.String);
[frames,disp_time,values,plot_values] = DispAndSave(hObject, eventdata, handles, MyClient, stop_time, scaling_voltage);

% We store all necessary output in the output structure.
output.values = values;
output.frames = frames;
output.disp_time = disp_time;

disp(['max = ', num2str(max(plot_values))]);

while MyClient.IsConnected().Connected
    MyClient.Disconnect();
    fprintf( '.' );
end
clear MyClient;

function [frames,disp_time,values, plot_values] = DispAndSave(hObject, eventdata, handles, MyClient, stop_time, scaling_voltage)

cla
h = animatedline('LineWidth',3,'Color',[1 0 0]);

xlabel('Time (s)')
ylabel('Torque (N-m)')
grid on
yline(str2double(handles.feedback_line.String), 'k--', 'linewidth', 2)
% Name of the analogue channel we want to read out
DeviceName= ['Mini wave EMG'];

% Start showing a lineplot showing the read out data.
frames = zeros(stop_time*100,1);
disp_time = zeros(stop_time*100,1);
values = zeros(stop_time*1000,1);
counter = 1;

tic;
% Loop until the message box is dismissed
k = 0;

while get(hObject,'Value')
    
    k = k+1;
    
    % Get a frame
    while MyClient.GetFrame().Result.Value ~= Result.Success
    end
    
    % Get the frame number
    Output_GetFrameNumber = MyClient.GetFrameNumber();
    
    % Store in vector
    frames(counter) = Output_GetFrameNumber.FrameNumber;
    
    % Get the number of subsamples associated with this device.
    % The system runs at 100Hz, but some analog devices work at eg 1000Hz.
    Output_GetDeviceOutputName = MyClient.GetDeviceOutputName( DeviceName, 3);
    Output_GetDeviceOutputSubsamples = MyClient.GetDeviceOutputSubsamples( DeviceName, Output_GetDeviceOutputName.DeviceOutputName );
    
    plot_value = 0;
    
    if Output_GetDeviceOutputSubsamples.DeviceOutputSubsamples > 0
    for DeviceOutputSubsample = 1:Output_GetDeviceOutputSubsamples.DeviceOutputSubsamples
        % Get the device output value
        value = MyClient.GetDeviceOutputValue( DeviceName , Output_GetDeviceOutputName.DeviceOutputName, DeviceOutputSubsample ).Value;
        values((counter-1)*10+DeviceOutputSubsample) = value;
        plot_value = plot_value + value;
    end
    
%     save_value(k) = abs(plot_value/double(DeviceOutputSubsample)) * scaling_voltage;
    save_value(k) = plot_value/double(DeviceOutputSubsample) * scaling_voltage;
    cur_value = save_value;
%     cur_value = movmean(save_value, [50 0]);
    
    plot_value = cur_value(k);
    plot_values(k) = plot_value;
    
%     if k == 100
%         keyboard
%     end
    %
    if plot_value ~= 0
        sample_time = toc;
        addpoints(h,sample_time,plot_value); %  hold on;
        drawnow;
        disp_time(counter) = sample_time;
    end
    
    if toc > stop_time
        break;
    end
    counter = counter + 1;
    end
    
end



function ymax_Callback(hObject, eventdata, handles)
% hObject    handle to ymax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ymax as text
%        str2double(get(hObject,'String')) returns contents of ymax as a double

handles.ylim = str2double(get(hObject,'String'));
% y_min = -handles.ylim;
% y_plus = handles.ylim;
% ylim([0 y_plus]);
% set(gca, 'ytick', (y_min:5:y_plus))



% --- Executes during object creation, after setting all properties.
function ymax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ymax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.ylim = str2double(get(hObject,'String'));



function feedback_line_Callback(hObject, eventdata, handles)
% hObject    handle to feedback_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of feedback_line as text
%        str2double(get(hObject,'String')) returns contents of feedback_line as a double

handles.feedback_line = str2double(get(hObject,'String'));
yline(handles.feedback_line,'k--')

% --- Executes during object creation, after setting all properties.
function feedback_line_CreateFcn(hObject, eventdata, handles)
% hObject    handle to feedback_line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function scale_factor_Callback(hObject, eventdata, handles)
% hObject    handle to scale_factor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of scale_factor as text
%        str2double(get(hObject,'String')) returns contents of scale_factor as a double

handles.scalefac = str2double(get(hObject,'String'));

% --- Executes during object creation, after setting all properties.
function scale_factor_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scale_factor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ymin_Callback(hObject, eventdata, handles)
% hObject    handle to ymin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ymin as text
%        str2double(get(hObject,'String')) returns contents of ymin as a double


% --- Executes during object creation, after setting all properties.
function ymin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ymin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
