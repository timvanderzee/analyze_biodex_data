function varargout = feedback(varargin)
% NEWFIG MATLAB code for feedback.fig
%      NEWFIG, by itself, creates a new NEWFIG or raises the existing
%      singleton*.
%
%      H = NEWFIG returns the handle to a new NEWFIG or the handle to
%      the existing singleton*.
%
%      NEWFIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NEWFIG.M with the given input arguments.
%
%      feedback('Property','Value',...) creates a new feedback or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before feedback_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to feedback_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help feedback

% Last Modified by GUIDE v2.5 15-Dec-2025 12:19:31

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @feedback_OpeningFcn, ...
    'gui_OutputFcn',  @feedback_OutputFcn, ...
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

% --- Executes just before feedback is made visible.
function feedback_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to feedback (see VARARGIN)

% Choose default command line output for feedback
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes feedback wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = feedback_OutputFcn(hObject, eventdata, handles)
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

% Program options
HostName = 'localhost:801';

% Make a new client
MyClient = Client();

while ~MyClient.IsConnected().Connected
    % Direct connection
    MyClient.Connect( HostName );
end

MyClient.EnableDeviceData(); % Enable ForcePlate/EMG... and other analog device data in the Vicon DataStream.
MyClient.SetStreamMode( StreamMode.ClientPull );

% Display and Save stuff
DispAndSave(hObject, eventdata, handles, MyClient, stop_time, scaling_voltage);

while MyClient.IsConnected().Connected
    MyClient.Disconnect();
    fprintf( '.' );
end
clear MyClient;

function [] = DispAndSave(hObject, eventdata, handles, MyClient)

stop_time       = str2double(handles.stop_time.String);
scaling_voltage = str2double(handles.scale_factor.String);

% define a line in the plot
g = plot(handles.axes1, 0, 0);

handles.axes1.YLim = [str2double(handles.ymin.String) str2double(handles.ymax.String)];
handles.axes1.XLim = [0 1.5];

xlabel('Time (s)')
ylabel('Torque (N-m)')
grid on
yline(str2double(handles.feedback_line.String), 'k--', 'linewidth', 2)
yline(str2double(handles.line2.String), 'k--', 'linewidth', 2)

% Name of the analogue channel we want to read out
% DeviceName= ['Mini wave EMG'];
DeviceName = handles.channel_name.String{handles.channel_name.Value};
DeviceName = 'Biodex';

% scale factor
scale_fac = [1 scaling_voltage];

% Loop until the message box is dismissed
k = 0;

% pre-allocate 
N = stop_time * 100;
all_values  = nan(1,N);
plot_values = nan(1,N);

% continue until we pas the stop_time
tic;
sample_time = 0;
while sample_time < stop_time
    
    k = k+1;
    
    % Get a frame
    while MyClient.GetFrame().Result.Value ~= Result.Success
    end
    
    
    % Get the number of subsamples associated with this device.
    % The system runs at 100Hz, but some analog devices work at eg 1000Hz.
%     Output_GetDeviceOutputName = MyClient.GetDeviceOutputName( DeviceName, str2double(handles.channel_number.String));
%     Output_GetDeviceOutputSubsamples = MyClient.GetDeviceOutputSubsamples( DeviceName, Output_GetDeviceOutputName.DeviceOutputName );

    Output_GetDeviceOutputSubsamples.DeviceOutputSubsamples = 5;
    
    if Output_GetDeviceOutputSubsamples.DeviceOutputSubsamples > 0
        
        for i = 1:2 % loop over channels
            if i == 1
                DeviceName = 'Biodex';
                Output_GetDeviceOutputName.DeviceOutputName = 'Angle';
            else
                DeviceName = 'Mini wave EMG';
                Output_GetDeviceOutputName.DeviceOutputName = '2';
            end
            
           
            values = nan(1, Output_GetDeviceOutputSubsamples.DeviceOutputSubsamples);
            for DeviceOutputSubsample = 1:Output_GetDeviceOutputSubsamples.DeviceOutputSubsamples
                % Get the device output value
%                 values(DeviceOutputSubsample) = MyClient.GetDeviceOutputValue( DeviceName , Output_GetDeviceOutputName.DeviceOutputName, DeviceOutputSubsample ).Value;
                values(DeviceOutputSubsample) = randn(1);
            end
            
            % take average over subsamples
            all_values(k,i) = abs(mean(values) * scale_fac(i));
            
            % optionally filter
            if handles.do_filter.Value
                plot_values(1:k,i) = movmean(all_values(1:k,i), [str2double(handles.filter_samps.String) 0]);
            else
                plot_values(1:k,i) = all_values(1:k,i);
            end
           
        end
       
        % plot
        N = max(k - 200, 1);
        set(g, 'xdata', plot_values(N:end,1),plot_values(N:end,2))
        drawnow;

        % check the current time
        sample_time = toc;

    end
end


disp(['max = ', num2str(max(plot_values))]);
disp(['mean = ', num2str(mean(plot_values))]);



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


% --- Executes on selection change in channel_name.
function channel_name_Callback(hObject, eventdata, handles)
% hObject    handle to channel_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns channel_name contents as cell array
%        contents{get(hObject,'Value')} returns selected item from channel_name


% --- Executes during object creation, after setting all properties.
function channel_name_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function channel_number_Callback(hObject, eventdata, handles)
% hObject    handle to channel_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of channel_number as text
%        str2double(get(hObject,'String')) returns contents of channel_number as a double


% --- Executes during object creation, after setting all properties.
function channel_number_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channel_number (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function stop_time_Callback(hObject, eventdata, handles)
% hObject    handle to stop_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stop_time as text
%        str2double(get(hObject,'String')) returns contents of stop_time as a double


% --- Executes during object creation, after setting all properties.
function stop_time_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stop_time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in do_filter.
function do_filter_Callback(hObject, eventdata, handles)
% hObject    handle to do_filter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of do_filter



function filter_samps_Callback(hObject, eventdata, handles)
% hObject    handle to filter_samps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filter_samps as text
%        str2double(get(hObject,'String')) returns contents of filter_samps as a double


% --- Executes during object creation, after setting all properties.
function filter_samps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filter_samps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function line2_Callback(hObject, eventdata, handles)
% hObject    handle to line2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of line2 as text
%        str2double(get(hObject,'String')) returns contents of line2 as a double


% --- Executes during object creation, after setting all properties.
function line2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to line2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function baseline_Callback(hObject, eventdata, handles)
% hObject    handle to baseline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of baseline as text
%        str2double(get(hObject,'String')) returns contents of baseline as a double


% --- Executes during object creation, after setting all properties.
function baseline_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baseline (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in stream.
function stream_Callback(hObject, eventdata, handles)
% hObject    handle to stream (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stream

Client.LoadViconDataStreamSDK();