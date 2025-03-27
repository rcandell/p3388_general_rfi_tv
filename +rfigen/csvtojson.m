function csvtojson(conf_file, csv_file, output_file)
% produces the Reactors part of the json file
%   Detailed explanation goes here
% Author: Rick Candell
% 
% (c) Copyright Rick Candell All Rights Reserved

% read the config file
fileID = fopen(conf_file, 'r');
json_data = fread(fileID, '*char')';
fclose(fileID);
config = jsondecode(json_data);  

hdr = jsonencode(config,"PrettyPrint",true);
hdr = hdr(1:end-2) + "," + newline;
fid = fopen(output_file,"w");
fprintf(fid,"%s", hdr);
fclose(fid);

% read csv file
T = readtable(csv_file);

% row by row convert to json
J = [];
N = height(T);
J = newline + """Reactors""" + ":" + "[" + newline;
for ii = 1:N
    
    r = T(ii,:);
    J = add_reactor(J, r);
    if ii ~= N
        J = J + "," + newline;
    end
    
end
J = J + "]" + "}" + newline;

% output
fid = fopen(output_file,"a");
fprintf(fid,"%s", J);
fclose(fid);

% read in for pretty printing
fid = fopen(output_file,"r");
json_data = fread(fid, '*char')';
fclose(fid);
jtxt = jsondecode(json_data);  
jtxt = jsonencode(jtxt,"PrettyPrint",true);

% now rewrite the file for pretty printing
fid = fopen(output_file,"w");
fprintf(fid,"%s", jtxt);
fclose(fid);

end

function s = add_reactor(s, r)

    s = s + "{" + newline;

    name = cell2mat(r.Name);
    s = add_string(s,"Name",name);
    s = add_comma_newline(s);

    jtype = cell2mat(r.type);
    s = add_string(s, "type", jtype);
    s = add_comma_newline(s);

    centerbin = r.centerbin;
    s = add_double(s, "centerbin", centerbin);
    s = add_comma_newline(s);

    ge_probs = table2array(r(:,4:7));
    s = add_array(s, "ge_probs", ge_probs);
    s = add_comma_newline(s);   

    s = begin_section(s, "bw_distr");
    bw_distr_type = cell2mat(r.bw_distr_type);
    s = add_string(s, "type", bw_distr_type);
    s = add_comma_newline(s);
    bw_distr_mean = r.bw_distr_mean;
    s = add_double(s, "mean", bw_distr_mean);
    s = add_comma_newline(s);    
    bw_distr_std  = r.bw_distr_std;
    s = add_double(s, "std", bw_distr_std);   
    s = end_section(s);
    s = add_comma_newline(s);

    s = begin_section(s, "pwr_distr");
    pwr_distr_type = cell2mat(r.pwr_distr_type);
    s = add_string(s, "type", pwr_distr_type);
    s = add_comma_newline(s);
    pwr_distr_mean = r.pwr_distr_mean;
    s = add_double(s, "mean", pwr_distr_mean);
    s = add_comma_newline(s);
    pwr_distr_std  = r.pwr_distr_std;
    s = add_double(s, "std", pwr_distr_std);
    s = end_section(s);

    s = s + "}";

end

function s = begin_section(s, name)
    s = s + """" + name + """" + ":" + "{" + newline;
end

function s = end_section(s)
    s = s + "}";
end

function s = add_string(s, name, value)
    s = s + """" + name + """" + ":" + """" + value + """"; 
end

function s = add_double(s, name, value)
    s = s + """" + name + """" + ":" + value; 
end

function s = add_array(s, name, value)
    sx = num2str(value,'%.4f,');
    sx = sx(1:end-1);
    s = s + """" + name + """" + ":[" + sx + "]"; 
end

function s = add_comma_newline(s)
    s = s + "," + newline;
end



