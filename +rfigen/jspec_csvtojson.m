function jspec_csvtojson(conf_file, csv_file, output_file)
% JSPEC_CSVTOJSON Convert CSV file to JSON for RFI reactors
%   This function reads a configuration file and a CSV file containing reactor
%   properties, and generates a JSON file (JSPEC) for use in RFI generation systems,
%   likely supporting the IEEE 3388 standard for industrial wireless testing.
%   The output JSON includes the configuration header and an array of reactors.
%
%   The CSV file must have the following columns in this order:
%   1. Name
%   2. type
%   3. centerbin
%   4. ge_prob_11
%   5. ge_prob_12
%   6. ge_prob_21
%   7. ge_prob_22
%   8. bw_distr_type
%   9. bw_distr_mean
%   10. bw_distr_std
%   11. pwr_distr_type
%   12. pwr_distr_mean
%   13. pwr_distr_std
%   14. pwr_shaping
%   15. pwr_shaping_std
%
%   Inputs:
%     conf_file - Path to the configuration JSON file
%     csv_file - Path to the CSV file with reactor properties
%     output_file - Path to the output JSON file
%
%   Outputs:
%     None (writes to output_file)
%
%   Author: Rick Candell
%   (c) Copyright Rick Candell All Rights Reserved

% Read the configuration file
% Loads configuration settings (e.g., spectrogram and IFFT parameters) into a MATLAB structure
fileID = fopen(conf_file, 'r');
json_data = fread(fileID, '*char')';
fclose(fileID);
config = jsondecode(json_data);  

% Write the configuration part of the JSON file
% Encodes the configuration as JSON, removes the closing brace, and adds a comma
% to prepare for appending the "Reactors" array
hdr = jsonencode(config, "PrettyPrint", true);
hdr = hdr(1:end-2) + "," + newline;
fid = fopen(output_file, "w");
fprintf(fid, "%s", hdr);
fclose(fid);

% Read the CSV file into a table
% Each row represents a reactor with its properties
T = readtable(csv_file);

% Initialize the "Reactors" array in the JSON
% Starts building the JSON string for the "Reactors" array
J = newline + """Reactors""" + ":" + "[" + newline;
N = height(T);
for ii = 1:N
    % Convert each table row to a JSON object representing a reactor
    r = T(ii,:);
    J = add_reactor(J, r);
    % Add a comma and newline after each reactor except the last
    if ii ~= N
        J = J + "," + newline;
    end
end
% Close the "Reactors" array and the entire JSON object
J = J + "]" + "}" + newline;

% Append the "Reactors" array to the JSON file
% Opens the file in append mode to add to the existing header
fid = fopen(output_file, "a");
fprintf(fid, "%s", J);
fclose(fid);

% Read the JSON file back for pretty printing
% Ensures the final JSON is human-readable by reformatting it
fid = fopen(output_file, "r");
json_data = fread(fid, '*char')';
fclose(fid);
jtxt = jsondecode(json_data);  
jtxt = jsonencode(jtxt, "PrettyPrint", true);

% Rewrite the file with pretty-printed JSON
% Overwrites the file with formatted JSON content
fid = fopen(output_file, "w");
fprintf(fid, "%s", jtxt);
fclose(fid);

end

function s = add_reactor(s, r)
% ADD_REACTOR Convert a table row to a JSON object for a reactor
%   Appends the JSON representation of a reactor to the current JSON string
%   based on the table row data

    % Start a new JSON object for the reactor
    s = s + "{" + newline;

    % Add "Name" field
    name = cell2mat(r.Name);
    s = add_string(s, "Name", name);
    s = add_comma_newline(s);

    % Add "type" field
    jtype = cell2mat(r.type);
    s = add_string(s, "type", jtype);
    s = add_comma_newline(s);

    % Add "centerbin" field
    centerbin = r.centerbin;
    s = add_double(s, "centerbin", centerbin);
    s = add_comma_newline(s);

    % Add "ge_probs" field as an array (columns 4 to 7)
    % Assumes columns 4-7 are ge_prob_11, ge_prob_12, ge_prob_21, ge_prob_22
    ge_probs = table2array(r(:,4:7));
    s = add_array(s, "ge_probs", ge_probs);
    s = add_comma_newline(s);   

    % Begin "bw_distr" section
    s = begin_section(s, "bw_distr");
    bw_distr_type = cell2mat(r.bw_distr_type);
    s = add_string(s, "type", bw_distr_type);
    s = add_comma_newline(s);
    bw_distr_mean = r.bw_distr_mean;
    s = add_double(s, "mean", bw_distr_mean);
    s = add_comma_newline(s);    
    bw_distr_std = r.bw_distr_std;
    s = add_double(s, "std", bw_distr_std);   
    s = end_section(s);
    s = add_comma_newline(s);

    % Begin "pwr_distr" section
    s = begin_section(s, "pwr_distr");
    pwr_distr_type = cell2mat(r.pwr_distr_type);
    s = add_string(s, "type", pwr_distr_type);
    s = add_comma_newline(s);
    pwr_distr_mean = r.pwr_distr_mean;
    s = add_double(s, "mean", pwr_distr_mean);
    s = add_comma_newline(s);
    pwr_distr_std = r.pwr_distr_std;
    s = add_double(s, "std", pwr_distr_std);
    s = end_section(s);
    s = add_comma_newline(s);

    % Begin "pwr_shaping" section
    s = begin_section(s, "pwr_shaping");
    pwr_shaping_on = r.pwr_shaping;
    s = add_double(s, "enabled", pwr_shaping_on);
    s = add_comma_newline(s);
    pwr_shaping_std = r.pwr_shaping_std;
    s = add_double(s, "std", pwr_shaping_std);
    s = end_section(s);    

    % Close reactor JSON object
    s = s + "}";

end

function s = begin_section(s, name)
% BEGIN_SECTION Start a new JSON section
%   Adds a key-value pair where the value is an object
    s = s + """" + name + """" + ":" + "{" + newline;
end

function s = end_section(s)
% END_SECTION Close the current JSON section
    s = s + "}";
end

function s = add_string(s, name, value)
% ADD_STRING Add a string field to the JSON
%   Formats the field as a quoted string
    s = s + """" + name + """" + ":" + """" + value + """"; 
end

function s = add_double(s, name, value)
% ADD_DOUBLE Add a numeric field to the JSON
%   Adds the number without quotes
    s = s + """" + name + """" + ":" + value; 
end

function s = add_array(s, name, value)
% ADD_ARRAY Add an array field to the JSON
%   Converts the array to a string with four decimal places, removing the trailing comma
    sx = num2str(value, '%.4f,');
    sx = sx(1:end-1);
    s = s + """" + name + """" + ":[" + sx + "]"; 
end

function s = add_comma_newline(s)
% ADD_COMMA_NEWLINE Add a comma and newline for readability
    s = s + "," + newline;
end