clear all;
%========================== Read PPM file ===========================================%
FALSE = 0;
TRUE = 1;
R = [];
G = [];
B = [];
fid = fopen ('snail.ppm', 'r');
%  Read the first line.
line = fgets (fid);
%  Verify that the first two characters are the "magic number".
%  Matlab strncmp returns 1 for equality, and 0 for inequality.
if  strncmp (line, 'P3', 2) == 0 
    return;
end
%  Move to the next noncomment line.
while ( 1 )
    line = fgets (fid);
    if  line(1) ~= '#' 
      break;
    end
end  
%  Extract NCOL and NROW.
[array, count] = sscanf ( line, '%d' );
ncol = array(1);
nrow = array(2);
%  Move to the next noncomment line.
while ( 1 )
    line = fgets (fid);
    if  line(1) ~= '#'  
      break;
    end
end
%  Extract MAXRGB, and ignore it.
[ array, count ] = sscanf ( line, '%d' );
maxRGB = array(1);
R = zeros (nrow, ncol);
G = zeros (nrow, ncol);
B = zeros (nrow, ncol);
i = 1;
j = 0;
p = 0;
done = FALSE;
while  done == FALSE 
%  Move to the next noncomment line.
    while ( 1 )
      line = fgets (fid);
      if  line(1) ~= '#' 
        break;
      end
    end
    [ array, count ] = sscanf ( line, '%d' );
%  Each value that you read goes into the "next" open entry.
%  When reading R, we update the row and column indices.
    for k = 1:count
      if p == 0
        j = j + 1;
        if  ncol < j 
          j = 1;
          i = i + 1;
        end
        R(i,j) = array(k);
      elseif  p == 1 
        G(i,j) = array(k);
      elseif  p == 2 
        B(i,j) = array(k);
        if  i == nrow && j == ncol 
          done = TRUE;
        end
      end
      p = mod ( p+1, 3 );
    end 
end
fclose (fid);
% %================ Code for RGB to YUV ==============%
Y = 0.299 * R + 0.587 * G + 0.114 * B; 
Cb = -0.1687 * R - 0.3313 * G + 0.5 * B + 128; 
Cr = 0.5 * R - 0.4187 * G - 0.0813 * B + 128; 
RGB = cat(3,R,G,B);
RGB = uint8(RGB);
YCbCr = cat(3,Y,Cb,Cr); 
YCbCr = uint8(YCbCr);
figure(1);
imshow(RGB);
figure(2);
imshow(YCbCr);
%===================================================%
% quantization matrix
quant_Y = [16,11,10,16,24,40,51,61;
           12,12,14,19,26,58,60,55;
           14,13,16,24,40,57,69,56;
           14,17,22,29,51,87,80,62;
           18,22,37,56,68,109,103,77;
           24,35,55,64,81,104,113,92;
           49,64,78,87,103,121,120,101;
           72,92,95,98,112,100,103,99];
quant_C = [17,18,24,47,99,99,99,99;
           18,21,26,66,99,99,99,99;
           24,26,56,99,99,99,99,99;
           47,66,99,99,99,99,99,99;
           99,99,99,99,99,99,99,99;
           99,99,99,99,99,99,99,99;
           99,99,99,99,99,99,99,99;
           99,99,99,99,99,99,99,99];
%========= Create DCT Matrix =======================%
S = eye(8)/2;
S(1,1) = 1/2/sqrt(2);
D = zeros(8,8);
for t = 0:7
    for w = 0:7
        D(w+1,t+1) = cos((2*t+1)*w*pi/16);
    end
end
D = S*D;
%================ Compression step ==================%
a = nrow;
b = ncol;
Y_1 = Y;
a_extra = 8*ceil(a/8) - a;
b_extra = 8*ceil(b/8) - b;
add_row_Y = Y(a,:);
add_row_Cb = Cb(a,:);
add_row_Cr = Cr(a,:);
for i = 1:a_extra
    Y = [Y;add_row_Y];
    Cb = [Cb;add_row_Cb];
    Cr = [Cr;add_row_Cr]; 
end
add_col_Y = Y(:,b);
add_col_Cb = Cb(:,b);
add_col_Cr = Cr(:,b);
for i = 1:b_extra
    Y = [Y,add_col_Y];
    Cb = [Cb,add_col_Cb];
    Cr = [Cr,add_col_Cr]; 
end
temp_Y = 0;
temp_Cb = 0;
temp_Cr = 0;
huffman_code = '';
a = a + a_extra;
b = b + b_extra;
for i = 1:8:a
    for j = 1:8:b
        Y_P0 = Y(i:i+7,j:j+7);  % extract 8x8 block
        Y_P = Y_P0 - 128;       % subtract 128
        Y_F = D*Y_P*D.';        % DCT 
        Y_Q = round(Y_F./quant_Y);  % Quantization
        Y_AC = run_length(Y_Q);   % run length coding for AC
        % DC DPCM coding
        Y_DC = Y_Q(1,1);
        Y_DC = Y_DC - temp_Y;
        temp_Y = Y_Q(1,1);
        % for Cb
        Cb_P0 = Cb(i:i+7,j:j+7);
        Cb_P = Cb_P0 - 128;
        Cb_F = D*Cb_P*D.';
        Cb_Q = round(Cb_F./quant_C);
        Cb_AC = run_length(Cb_Q);    % run length coding for AC
        % DC DPCM coding
        Cb_DC = Cb_Q(1,1);
        Cb_DC = Cb_DC - temp_Cb;
        temp_Cb = Cb_Q(1,1);
        % for Cr
        Cr_P0 = Cr(i:i+7,j:j+7);
        Cr_P = Cr_P0 - 128;
        Cr_F = D*Cr_P*D.';
        Cr_Q = round(Cr_F./quant_C);
        Cr_AC = run_length(Cr_Q); %  run length coding for AC
        % DC DPCM coding
        Cr_DC = Cr_Q(1,1);
        Cr_DC = Cr_DC - temp_Cr;
        temp_Cr = Cr_Q(1,1);
        % get the huffman codes for DC and AC
        temp_huffman_Y = huff_code_Y(Y_DC, Y_AC);
        % concatenate this code with the already calculated huffman code
        huffman_code = strcat(huffman_code,temp_huffman_Y);
        temp_huffman_Cb = huff_code_C(Cb_DC, Cb_AC);
        % concatenate this code with the already calculated huffman code
        huffman_code = strcat(huffman_code,temp_huffman_Cb);
        temp_huffman_Cr = huff_code_C(Cr_DC, Cr_AC);
        % concatenate this code with the already calculated huffman code
        huffman_code = strcat(huffman_code,temp_huffman_Cr);
    end
end
huffman_code = char(huffman_code);  % convert from cell to string
length_huff = length(huffman_code);
% check if huffman code length is a multiple of byte or not
check_length = mod(length_huff,8);
if check_length~=0
    itr = ceil(length_huff/8);    % calculate the number of extra bits to add to huffman code to make its length an interger multiple of byte
    itr = 8*itr - length_huff;
    for k = 1:itr
        huffman_code = strcat(huffman_code,'1');   % add 1 to huffman code
    end
end   
% convert huffman code in the form of bytes
h_code_byte = [];
ent_c_i = 1;
length_huff = length(huffman_code);
for i = 1:8:length_huff
    one_byte = huffman_code(i:i+7); % get 8 bits or one byte
    h_code_byte(ent_c_i) = bin2dec(one_byte);
    if h_code_byte(ent_c_i) == 255
        ent_c_i = ent_c_i + 1;        % if byte is 255 or ff then append 0 so that reader does not consider as a header file
        h_code_byte(ent_c_i) = 0;
    end
    ent_c_i = ent_c_i + 1;
end
%========================Write JPEG============================================================================================================%
jpeg_file = fopen('snail.jpg','w');
% start of image header
s_image = {'ff','d8','ff','e0','00','10','4a','46','49','46','00','01','01','00','00','01','00','01','00','00'};
s_image_w = hex2dec(s_image);
% Luminance quantization table header
quant_h_Y = {'ff','db','00','43','00'};
quant_h_Y_w = hex2dec(quant_h_Y);
% Luminance quantization table
quant_Y = [16,11,12,14,12,10,16,14,13,14,18,17,16,19,24,40,26,24,22,22,24,49,35,37,29,40,58,51,61,60,57,51,56,55,64,72,92,78,64,68,87,69,55,56,80,109,81,87,95,98,103,104,103,62,77,113,121,112,100,120,92,101,103,99];
% Chrominancec quantization table header
quant_h_C = {'ff','db','00','43','01'};
quant_h_C_w = hex2dec(quant_h_C);
% Chrominance quantization table
quant_C = [17,18,18,24,21,24,47,26,26,47,99,66,56,66,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99,99];
rows = dec2hex(a,4);
columns = dec2hex(b,4);
% start of frame header
s_frame = {'ff','c0','00','11','08',rows(1:2),rows(3:4),columns(1:2),columns(3:4),'03','01','11','00','02','11','01','03','11','01'};
s_frame_w = hex2dec(s_frame);
huff_Y_DC = {'ff','c4','00','1f','00','00','01','05','01','01','01','01','01','01','00','00','00','00','00','00','00','00','01','02','03','04','05','06','07','08','09','0a','0b'};
huff_Y_DC_w = hex2dec(huff_Y_DC);
huff_Y_AC = {'ff','c4','00','b5','10','00','02','01','03','03','02','04','03','05','05','04','04','00','00','01','7d','01', '02', '03', '00', '04', '11', '05', '12','21', '31', '41', '06', '13', '51', '61', '07','22', '71', '14', '32', '81', '91', 'a1', '08','23', '42', 'b1', 'c1', '15', '52', 'd1', 'f0','24', '33', '62', '72', '82', '09', '0a', '16','17', '18', '19', '1a', '25', '26', '27', '28','29', '2a', '34', '35', '36', '37', '38', '39','3a', '43', '44', '45', '46', '47', '48', '49', '4a', '53', '54', '55', '56', '57', '58', '59','5a', '63', '64', '65', '66', '67', '68', '69', '6a', '73', '74', '75', '76', '77', '78', '79','7a', '83', '84', '85', '86', '87', '88', '89','8a', '92', '93', '94', '95', '96', '97', '98','99', '9a', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7','a8', 'a9', 'aa', 'b2', 'b3', 'b4', 'b5', 'b6','b7', 'b8', 'b9', 'ba', 'c2', 'c3', 'c4', 'c5','c6', 'c7', 'c8', 'c9', 'ca', 'd2', 'd3', 'd4','d5', 'd6', 'd7', 'd8', 'd9', 'da', 'e1', 'e2','e3', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'ea','f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8','f9', 'fa'};
huff_Y_AC_w = hex2dec(huff_Y_AC);
huff_C_DC = {'ff','c4','00','1f','01','00','03','01','01','01','01','01','01','01','01','01','00','00','00','00','00','00','01','02','03','04','05','06','07','08','09','0a','0b'};
huff_C_DC_w = hex2dec(huff_C_DC);
huff_C_AC = {'ff','c4','00','b5','11','00','02','01','03','03','02','04','03','05','05','04','04','00','00','01','7d','01', '02', '03', '00', '04', '11', '05', '12','21', '31', '41', '06', '13', '51', '61', '07','22', '71', '14', '32', '81', '91', 'a1', '08','23', '42', 'b1', 'c1', '15', '52', 'd1', 'f0','24', '33', '62', '72', '82', '09', '0a', '16','17', '18', '19', '1a', '25', '26', '27', '28','29', '2a', '34', '35', '36', '37', '38', '39','3a', '43', '44', '45', '46', '47', '48', '49', '4a', '53', '54', '55', '56', '57', '58', '59','5a', '63', '64', '65', '66', '67', '68', '69', '6a', '73', '74', '75', '76', '77', '78', '79','7a', '83', '84', '85', '86', '87', '88', '89','8a', '92', '93', '94', '95', '96', '97', '98','99', '9a', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7','a8', 'a9', 'aa', 'b2', 'b3', 'b4', 'b5', 'b6','b7', 'b8', 'b9', 'ba', 'c2', 'c3', 'c4', 'c5','c6', 'c7', 'c8', 'c9', 'ca', 'd2', 'd3', 'd4','d5', 'd6', 'd7', 'd8', 'd9', 'da', 'e1', 'e2','e3', 'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'ea','f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8','f9', 'fa'};
huff_C_AC_w = hex2dec(huff_C_AC);
% start of scan header
s_scan = {'ff','da','00','0c','03','01','00','02','11','03','11','00','3f','00'};
s_scan_w = hex2dec(s_scan);
% end of image
e_image = {'ff','d9'};
e_image_w = hex2dec(e_image);
output = [s_image_w',quant_h_Y_w',quant_Y,quant_h_C_w',quant_C,s_frame_w',huff_Y_DC_w',huff_Y_AC_w',huff_C_DC_w',huff_C_AC_w',s_scan_w',h_code_byte,e_image_w'];
fwrite(jpeg_file,output,'uint8');
fclose (jpeg_file);