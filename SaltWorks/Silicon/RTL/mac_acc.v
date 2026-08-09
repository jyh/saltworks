`default_nettype none

module mac_acc (
    input  wire i0,
    input  wire i1,
    input  wire i2,
    input  wire i3,
    input  wire i4,
    input  wire i5,
    input  wire i6,
    input  wire i7,
    input  wire i8,
    input  wire i9,
    input  wire i10,
    input  wire i11,
    input  wire i12,
    input  wire i13,
    input  wire i14,
    input  wire i15,
    input  wire i16,
    input  wire i17,
    input  wire i18,
    input  wire i19,
    input  wire i20,
    input  wire i21,
    input  wire i22,
    input  wire i23,
    input  wire i24,
    input  wire i25,
    input  wire i26,
    input  wire i27,
    input  wire i28,
    input  wire i29,
    input  wire i30,
    input  wire i31,
    input  wire i32,
    input  wire i33,
    input  wire i34,
    input  wire i35,
    input  wire i36,
    input  wire i37,
    input  wire i38,
    input  wire i39,
    input  wire i40,
    input  wire i41,
    input  wire i42,
    input  wire i43,
    input  wire i44,
    input  wire i45,
    input  wire i46,
    input  wire i47,
    input  wire i48,
    input  wire i49,
    input  wire i50,
    input  wire i51,
    input  wire i52,
    input  wire i53,
    input  wire i54,
    input  wire i55,
    input  wire i56,
    input  wire i57,
    input  wire i58,
    input  wire i59,
    input  wire i60,
    input  wire i61,
    input  wire i62,
    input  wire i63,
    input  wire i64,
    output wire o0,
    output wire o1,
    output wire o2,
    output wire o3,
    output wire o4,
    output wire o5,
    output wire o6,
    output wire o7,
    output wire o8,
    output wire o9,
    output wire o10,
    output wire o11,
    output wire o12,
    output wire o13,
    output wire o14,
    output wire o15,
    output wire o16,
    output wire o17,
    output wire o18,
    output wire o19,
    output wire o20,
    output wire o21,
    output wire o22,
    output wire o23,
    output wire o24,
    output wire o25,
    output wire o26,
    output wire o27,
    output wire o28,
    output wire o29,
    output wire o30,
    output wire o31,
    output wire o32,
    output wire o33,
    output wire o34,
    output wire o35,
    output wire o36,
    output wire o37,
    output wire o38,
    output wire o39,
    output wire o40,
    output wire o41,
    output wire o42,
    output wire o43,
    output wire o44,
    output wire o45,
    output wire o46,
    output wire o47,
    output wire o48,
    output wire o49,
    output wire o50,
    output wire o51,
    output wire o52,
    output wire o53,
    output wire o54,
    output wire o55,
    output wire o56,
    output wire o57,
    output wire o58,
    output wire o59,
    output wire o60,
    output wire o61,
    output wire o62,
    output wire o63
);
  wire n65;
  wire n66;
  wire n67;
  wire n68;
  wire n69;
  wire n70;
  wire n71;
  wire n72;
  wire n73;
  wire n74;
  wire n75;
  wire n76;
  wire n77;
  wire n78;
  wire n79;
  wire n80;
  wire n81;
  wire n82;
  wire n83;
  wire n84;
  wire n85;
  wire n86;
  wire n87;
  wire n88;
  wire n89;
  wire n90;
  wire n91;
  wire n92;
  wire n93;
  wire n94;
  wire n95;
  wire n96;
  wire n97;
  wire n98;
  wire n99;
  wire n100;
  wire n101;
  wire n102;
  wire n103;
  wire n104;
  wire n105;
  wire n106;
  wire n107;
  wire n108;
  wire n109;
  wire n110;
  wire n111;
  wire n112;
  wire n113;
  wire n114;
  wire n115;
  wire n116;
  wire n117;
  wire n118;
  wire n119;
  wire n120;
  wire n121;
  wire n122;
  wire n123;
  wire n124;
  wire n125;
  wire n126;
  wire n127;
  wire n128;
  wire n129;
  wire n130;
  wire n131;
  wire n132;
  wire n133;
  wire n134;
  wire n135;
  wire n136;
  wire n137;
  wire n138;
  wire n139;
  wire n140;
  wire n141;
  wire n142;
  wire n143;
  wire n144;
  wire n145;
  wire n146;
  wire n147;
  wire n148;
  wire n149;
  wire n150;
  wire n151;
  wire n152;
  wire n153;
  wire n154;
  wire n155;
  wire n156;
  wire n157;
  wire n158;
  wire n159;
  wire n160;
  wire n161;
  wire n162;
  wire n163;
  wire n164;
  wire n165;
  wire n166;
  wire n167;
  wire n168;
  wire n169;
  wire n170;
  wire n171;
  wire n172;
  wire n173;
  wire n174;
  wire n175;
  wire n176;
  wire n177;
  wire n178;
  wire n179;
  wire n180;
  wire n181;
  wire n182;
  wire n183;
  wire n184;
  wire n185;
  wire n186;
  wire n187;
  wire n188;
  wire n189;
  wire n190;
  wire n191;
  wire n192;
  wire n193;
  wire n194;
  wire n195;
  wire n196;
  wire n197;
  wire n198;
  wire n199;
  wire n200;
  wire n201;
  wire n202;
  wire n203;
  wire n204;
  wire n205;
  wire n206;
  wire n207;
  wire n208;
  wire n209;
  wire n210;
  wire n211;
  wire n212;
  wire n213;
  wire n214;
  wire n215;
  wire n216;
  wire n217;
  wire n218;
  wire n219;
  wire n220;
  wire n221;
  wire n222;
  wire n223;
  wire n224;

  sky130_fd_sc_hd__xor2_1 g65 (.A(i33), .B(i0), .X(n65));
  sky130_fd_sc_hd__xor2_1 g66 (.A(n65), .B(i32), .X(n66));
  sky130_fd_sc_hd__and2_1 g67 (.A(i33), .B(i0), .X(n67));
  sky130_fd_sc_hd__and2_1 g68 (.A(n65), .B(i32), .X(n68));
  sky130_fd_sc_hd__or2_1 g69 (.A(n67), .B(n68), .X(n69));
  sky130_fd_sc_hd__xor2_1 g70 (.A(i34), .B(i1), .X(n70));
  sky130_fd_sc_hd__xor2_1 g71 (.A(n70), .B(n69), .X(n71));
  sky130_fd_sc_hd__and2_1 g72 (.A(i34), .B(i1), .X(n72));
  sky130_fd_sc_hd__and2_1 g73 (.A(n70), .B(n69), .X(n73));
  sky130_fd_sc_hd__or2_1 g74 (.A(n72), .B(n73), .X(n74));
  sky130_fd_sc_hd__xor2_1 g75 (.A(i35), .B(i2), .X(n75));
  sky130_fd_sc_hd__xor2_1 g76 (.A(n75), .B(n74), .X(n76));
  sky130_fd_sc_hd__and2_1 g77 (.A(i35), .B(i2), .X(n77));
  sky130_fd_sc_hd__and2_1 g78 (.A(n75), .B(n74), .X(n78));
  sky130_fd_sc_hd__or2_1 g79 (.A(n77), .B(n78), .X(n79));
  sky130_fd_sc_hd__xor2_1 g80 (.A(i36), .B(i3), .X(n80));
  sky130_fd_sc_hd__xor2_1 g81 (.A(n80), .B(n79), .X(n81));
  sky130_fd_sc_hd__and2_1 g82 (.A(i36), .B(i3), .X(n82));
  sky130_fd_sc_hd__and2_1 g83 (.A(n80), .B(n79), .X(n83));
  sky130_fd_sc_hd__or2_1 g84 (.A(n82), .B(n83), .X(n84));
  sky130_fd_sc_hd__xor2_1 g85 (.A(i37), .B(i4), .X(n85));
  sky130_fd_sc_hd__xor2_1 g86 (.A(n85), .B(n84), .X(n86));
  sky130_fd_sc_hd__and2_1 g87 (.A(i37), .B(i4), .X(n87));
  sky130_fd_sc_hd__and2_1 g88 (.A(n85), .B(n84), .X(n88));
  sky130_fd_sc_hd__or2_1 g89 (.A(n87), .B(n88), .X(n89));
  sky130_fd_sc_hd__xor2_1 g90 (.A(i38), .B(i5), .X(n90));
  sky130_fd_sc_hd__xor2_1 g91 (.A(n90), .B(n89), .X(n91));
  sky130_fd_sc_hd__and2_1 g92 (.A(i38), .B(i5), .X(n92));
  sky130_fd_sc_hd__and2_1 g93 (.A(n90), .B(n89), .X(n93));
  sky130_fd_sc_hd__or2_1 g94 (.A(n92), .B(n93), .X(n94));
  sky130_fd_sc_hd__xor2_1 g95 (.A(i39), .B(i6), .X(n95));
  sky130_fd_sc_hd__xor2_1 g96 (.A(n95), .B(n94), .X(n96));
  sky130_fd_sc_hd__and2_1 g97 (.A(i39), .B(i6), .X(n97));
  sky130_fd_sc_hd__and2_1 g98 (.A(n95), .B(n94), .X(n98));
  sky130_fd_sc_hd__or2_1 g99 (.A(n97), .B(n98), .X(n99));
  sky130_fd_sc_hd__xor2_1 g100 (.A(i40), .B(i7), .X(n100));
  sky130_fd_sc_hd__xor2_1 g101 (.A(n100), .B(n99), .X(n101));
  sky130_fd_sc_hd__and2_1 g102 (.A(i40), .B(i7), .X(n102));
  sky130_fd_sc_hd__and2_1 g103 (.A(n100), .B(n99), .X(n103));
  sky130_fd_sc_hd__or2_1 g104 (.A(n102), .B(n103), .X(n104));
  sky130_fd_sc_hd__xor2_1 g105 (.A(i41), .B(i8), .X(n105));
  sky130_fd_sc_hd__xor2_1 g106 (.A(n105), .B(n104), .X(n106));
  sky130_fd_sc_hd__and2_1 g107 (.A(i41), .B(i8), .X(n107));
  sky130_fd_sc_hd__and2_1 g108 (.A(n105), .B(n104), .X(n108));
  sky130_fd_sc_hd__or2_1 g109 (.A(n107), .B(n108), .X(n109));
  sky130_fd_sc_hd__xor2_1 g110 (.A(i42), .B(i9), .X(n110));
  sky130_fd_sc_hd__xor2_1 g111 (.A(n110), .B(n109), .X(n111));
  sky130_fd_sc_hd__and2_1 g112 (.A(i42), .B(i9), .X(n112));
  sky130_fd_sc_hd__and2_1 g113 (.A(n110), .B(n109), .X(n113));
  sky130_fd_sc_hd__or2_1 g114 (.A(n112), .B(n113), .X(n114));
  sky130_fd_sc_hd__xor2_1 g115 (.A(i43), .B(i10), .X(n115));
  sky130_fd_sc_hd__xor2_1 g116 (.A(n115), .B(n114), .X(n116));
  sky130_fd_sc_hd__and2_1 g117 (.A(i43), .B(i10), .X(n117));
  sky130_fd_sc_hd__and2_1 g118 (.A(n115), .B(n114), .X(n118));
  sky130_fd_sc_hd__or2_1 g119 (.A(n117), .B(n118), .X(n119));
  sky130_fd_sc_hd__xor2_1 g120 (.A(i44), .B(i11), .X(n120));
  sky130_fd_sc_hd__xor2_1 g121 (.A(n120), .B(n119), .X(n121));
  sky130_fd_sc_hd__and2_1 g122 (.A(i44), .B(i11), .X(n122));
  sky130_fd_sc_hd__and2_1 g123 (.A(n120), .B(n119), .X(n123));
  sky130_fd_sc_hd__or2_1 g124 (.A(n122), .B(n123), .X(n124));
  sky130_fd_sc_hd__xor2_1 g125 (.A(i45), .B(i12), .X(n125));
  sky130_fd_sc_hd__xor2_1 g126 (.A(n125), .B(n124), .X(n126));
  sky130_fd_sc_hd__and2_1 g127 (.A(i45), .B(i12), .X(n127));
  sky130_fd_sc_hd__and2_1 g128 (.A(n125), .B(n124), .X(n128));
  sky130_fd_sc_hd__or2_1 g129 (.A(n127), .B(n128), .X(n129));
  sky130_fd_sc_hd__xor2_1 g130 (.A(i46), .B(i13), .X(n130));
  sky130_fd_sc_hd__xor2_1 g131 (.A(n130), .B(n129), .X(n131));
  sky130_fd_sc_hd__and2_1 g132 (.A(i46), .B(i13), .X(n132));
  sky130_fd_sc_hd__and2_1 g133 (.A(n130), .B(n129), .X(n133));
  sky130_fd_sc_hd__or2_1 g134 (.A(n132), .B(n133), .X(n134));
  sky130_fd_sc_hd__xor2_1 g135 (.A(i47), .B(i14), .X(n135));
  sky130_fd_sc_hd__xor2_1 g136 (.A(n135), .B(n134), .X(n136));
  sky130_fd_sc_hd__and2_1 g137 (.A(i47), .B(i14), .X(n137));
  sky130_fd_sc_hd__and2_1 g138 (.A(n135), .B(n134), .X(n138));
  sky130_fd_sc_hd__or2_1 g139 (.A(n137), .B(n138), .X(n139));
  sky130_fd_sc_hd__xor2_1 g140 (.A(i48), .B(i15), .X(n140));
  sky130_fd_sc_hd__xor2_1 g141 (.A(n140), .B(n139), .X(n141));
  sky130_fd_sc_hd__and2_1 g142 (.A(i48), .B(i15), .X(n142));
  sky130_fd_sc_hd__and2_1 g143 (.A(n140), .B(n139), .X(n143));
  sky130_fd_sc_hd__or2_1 g144 (.A(n142), .B(n143), .X(n144));
  sky130_fd_sc_hd__xor2_1 g145 (.A(i49), .B(i16), .X(n145));
  sky130_fd_sc_hd__xor2_1 g146 (.A(n145), .B(n144), .X(n146));
  sky130_fd_sc_hd__and2_1 g147 (.A(i49), .B(i16), .X(n147));
  sky130_fd_sc_hd__and2_1 g148 (.A(n145), .B(n144), .X(n148));
  sky130_fd_sc_hd__or2_1 g149 (.A(n147), .B(n148), .X(n149));
  sky130_fd_sc_hd__xor2_1 g150 (.A(i50), .B(i17), .X(n150));
  sky130_fd_sc_hd__xor2_1 g151 (.A(n150), .B(n149), .X(n151));
  sky130_fd_sc_hd__and2_1 g152 (.A(i50), .B(i17), .X(n152));
  sky130_fd_sc_hd__and2_1 g153 (.A(n150), .B(n149), .X(n153));
  sky130_fd_sc_hd__or2_1 g154 (.A(n152), .B(n153), .X(n154));
  sky130_fd_sc_hd__xor2_1 g155 (.A(i51), .B(i18), .X(n155));
  sky130_fd_sc_hd__xor2_1 g156 (.A(n155), .B(n154), .X(n156));
  sky130_fd_sc_hd__and2_1 g157 (.A(i51), .B(i18), .X(n157));
  sky130_fd_sc_hd__and2_1 g158 (.A(n155), .B(n154), .X(n158));
  sky130_fd_sc_hd__or2_1 g159 (.A(n157), .B(n158), .X(n159));
  sky130_fd_sc_hd__xor2_1 g160 (.A(i52), .B(i19), .X(n160));
  sky130_fd_sc_hd__xor2_1 g161 (.A(n160), .B(n159), .X(n161));
  sky130_fd_sc_hd__and2_1 g162 (.A(i52), .B(i19), .X(n162));
  sky130_fd_sc_hd__and2_1 g163 (.A(n160), .B(n159), .X(n163));
  sky130_fd_sc_hd__or2_1 g164 (.A(n162), .B(n163), .X(n164));
  sky130_fd_sc_hd__xor2_1 g165 (.A(i53), .B(i20), .X(n165));
  sky130_fd_sc_hd__xor2_1 g166 (.A(n165), .B(n164), .X(n166));
  sky130_fd_sc_hd__and2_1 g167 (.A(i53), .B(i20), .X(n167));
  sky130_fd_sc_hd__and2_1 g168 (.A(n165), .B(n164), .X(n168));
  sky130_fd_sc_hd__or2_1 g169 (.A(n167), .B(n168), .X(n169));
  sky130_fd_sc_hd__xor2_1 g170 (.A(i54), .B(i21), .X(n170));
  sky130_fd_sc_hd__xor2_1 g171 (.A(n170), .B(n169), .X(n171));
  sky130_fd_sc_hd__and2_1 g172 (.A(i54), .B(i21), .X(n172));
  sky130_fd_sc_hd__and2_1 g173 (.A(n170), .B(n169), .X(n173));
  sky130_fd_sc_hd__or2_1 g174 (.A(n172), .B(n173), .X(n174));
  sky130_fd_sc_hd__xor2_1 g175 (.A(i55), .B(i22), .X(n175));
  sky130_fd_sc_hd__xor2_1 g176 (.A(n175), .B(n174), .X(n176));
  sky130_fd_sc_hd__and2_1 g177 (.A(i55), .B(i22), .X(n177));
  sky130_fd_sc_hd__and2_1 g178 (.A(n175), .B(n174), .X(n178));
  sky130_fd_sc_hd__or2_1 g179 (.A(n177), .B(n178), .X(n179));
  sky130_fd_sc_hd__xor2_1 g180 (.A(i56), .B(i23), .X(n180));
  sky130_fd_sc_hd__xor2_1 g181 (.A(n180), .B(n179), .X(n181));
  sky130_fd_sc_hd__and2_1 g182 (.A(i56), .B(i23), .X(n182));
  sky130_fd_sc_hd__and2_1 g183 (.A(n180), .B(n179), .X(n183));
  sky130_fd_sc_hd__or2_1 g184 (.A(n182), .B(n183), .X(n184));
  sky130_fd_sc_hd__xor2_1 g185 (.A(i57), .B(i24), .X(n185));
  sky130_fd_sc_hd__xor2_1 g186 (.A(n185), .B(n184), .X(n186));
  sky130_fd_sc_hd__and2_1 g187 (.A(i57), .B(i24), .X(n187));
  sky130_fd_sc_hd__and2_1 g188 (.A(n185), .B(n184), .X(n188));
  sky130_fd_sc_hd__or2_1 g189 (.A(n187), .B(n188), .X(n189));
  sky130_fd_sc_hd__xor2_1 g190 (.A(i58), .B(i25), .X(n190));
  sky130_fd_sc_hd__xor2_1 g191 (.A(n190), .B(n189), .X(n191));
  sky130_fd_sc_hd__and2_1 g192 (.A(i58), .B(i25), .X(n192));
  sky130_fd_sc_hd__and2_1 g193 (.A(n190), .B(n189), .X(n193));
  sky130_fd_sc_hd__or2_1 g194 (.A(n192), .B(n193), .X(n194));
  sky130_fd_sc_hd__xor2_1 g195 (.A(i59), .B(i26), .X(n195));
  sky130_fd_sc_hd__xor2_1 g196 (.A(n195), .B(n194), .X(n196));
  sky130_fd_sc_hd__and2_1 g197 (.A(i59), .B(i26), .X(n197));
  sky130_fd_sc_hd__and2_1 g198 (.A(n195), .B(n194), .X(n198));
  sky130_fd_sc_hd__or2_1 g199 (.A(n197), .B(n198), .X(n199));
  sky130_fd_sc_hd__xor2_1 g200 (.A(i60), .B(i27), .X(n200));
  sky130_fd_sc_hd__xor2_1 g201 (.A(n200), .B(n199), .X(n201));
  sky130_fd_sc_hd__and2_1 g202 (.A(i60), .B(i27), .X(n202));
  sky130_fd_sc_hd__and2_1 g203 (.A(n200), .B(n199), .X(n203));
  sky130_fd_sc_hd__or2_1 g204 (.A(n202), .B(n203), .X(n204));
  sky130_fd_sc_hd__xor2_1 g205 (.A(i61), .B(i28), .X(n205));
  sky130_fd_sc_hd__xor2_1 g206 (.A(n205), .B(n204), .X(n206));
  sky130_fd_sc_hd__and2_1 g207 (.A(i61), .B(i28), .X(n207));
  sky130_fd_sc_hd__and2_1 g208 (.A(n205), .B(n204), .X(n208));
  sky130_fd_sc_hd__or2_1 g209 (.A(n207), .B(n208), .X(n209));
  sky130_fd_sc_hd__xor2_1 g210 (.A(i62), .B(i29), .X(n210));
  sky130_fd_sc_hd__xor2_1 g211 (.A(n210), .B(n209), .X(n211));
  sky130_fd_sc_hd__and2_1 g212 (.A(i62), .B(i29), .X(n212));
  sky130_fd_sc_hd__and2_1 g213 (.A(n210), .B(n209), .X(n213));
  sky130_fd_sc_hd__or2_1 g214 (.A(n212), .B(n213), .X(n214));
  sky130_fd_sc_hd__xor2_1 g215 (.A(i63), .B(i30), .X(n215));
  sky130_fd_sc_hd__xor2_1 g216 (.A(n215), .B(n214), .X(n216));
  sky130_fd_sc_hd__and2_1 g217 (.A(i63), .B(i30), .X(n217));
  sky130_fd_sc_hd__and2_1 g218 (.A(n215), .B(n214), .X(n218));
  sky130_fd_sc_hd__or2_1 g219 (.A(n217), .B(n218), .X(n219));
  sky130_fd_sc_hd__xor2_1 g220 (.A(i64), .B(i31), .X(n220));
  sky130_fd_sc_hd__xor2_1 g221 (.A(n220), .B(n219), .X(n221));
  sky130_fd_sc_hd__and2_1 g222 (.A(i64), .B(i31), .X(n222));
  sky130_fd_sc_hd__and2_1 g223 (.A(n220), .B(n219), .X(n223));
  sky130_fd_sc_hd__or2_1 g224 (.A(n222), .B(n223), .X(n224));
  assign o0 = n66;
  assign o1 = n71;
  assign o2 = n76;
  assign o3 = n81;
  assign o4 = n86;
  assign o5 = n91;
  assign o6 = n96;
  assign o7 = n101;
  assign o8 = n106;
  assign o9 = n111;
  assign o10 = n116;
  assign o11 = n121;
  assign o12 = n126;
  assign o13 = n131;
  assign o14 = n136;
  assign o15 = n141;
  assign o16 = n146;
  assign o17 = n151;
  assign o18 = n156;
  assign o19 = n161;
  assign o20 = n166;
  assign o21 = n171;
  assign o22 = n176;
  assign o23 = n181;
  assign o24 = n186;
  assign o25 = n191;
  assign o26 = n196;
  assign o27 = n201;
  assign o28 = n206;
  assign o29 = n211;
  assign o30 = n216;
  assign o31 = n221;
  assign o32 = n66;
  assign o33 = n71;
  assign o34 = n76;
  assign o35 = n81;
  assign o36 = n86;
  assign o37 = n91;
  assign o38 = n96;
  assign o39 = n101;
  assign o40 = n106;
  assign o41 = n111;
  assign o42 = n116;
  assign o43 = n121;
  assign o44 = n126;
  assign o45 = n131;
  assign o46 = n136;
  assign o47 = n141;
  assign o48 = n146;
  assign o49 = n151;
  assign o50 = n156;
  assign o51 = n161;
  assign o52 = n166;
  assign o53 = n171;
  assign o54 = n176;
  assign o55 = n181;
  assign o56 = n186;
  assign o57 = n191;
  assign o58 = n196;
  assign o59 = n201;
  assign o60 = n206;
  assign o61 = n211;
  assign o62 = n216;
  assign o63 = n221;
endmodule

`default_nettype wire
