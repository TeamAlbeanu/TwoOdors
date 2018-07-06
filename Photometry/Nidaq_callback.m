function NIDAQ_callback(src,event)
% Callback function for nidaq acquisition. This function is used by a
% listener requiered when nidaq is started in background.

global nidaq
nidaq.ai_data = [nidaq.ai_data; event.Data];
