/*-----------------------------------------------------------------------------
-- Proyecto      : Modem Proximity para el programa SARE
-------------------------------------------------------------------------------
-- Archivo       : prbsx.v
-- Organizacion  : Fundacion Fulgor
-- Fecha         : 2014-04-18
-------------------------------------------------------------------------------
-- Descripcion   : PRBSx
-------------------------------------------------------------------------------
-- Autor         : Ariel Pola
-------------------------------------------------------------------------------
-- Copyright (C) 2014 Fundacion Fulgor  All rights reserved
-------------------------------------------------------------------------------
-- $Id: prbsx.v 3110 2015-07-03 17:36:16Z apola $
-------------------------------------------------------------------------------*/

//`include "../../include/global_parameters.v"
`include "../include/artyc_include.v"

module prbsx
  #(
    parameter NB_PRBS         = `NB_PRBS         ,
    parameter PRBS_LOW_ORDER  = `PRBS_LOW_ORDER  ,
    parameter PRBS_HIGH_ORDER = `PRBS_HIGH_ORDER ,
    parameter PRBS_SEED       = `PRBS_SEED_I
	)
    (
    output    out_data  ,
    input     in_enable ,
    input     in_reset  ,
    input     clock
     );
   

   reg [NB_PRBS - 1 : 0] data;
   
   assign                out_data = data[NB_PRBS-1];
   
   always @(posedge clock) begin:rnum
	  if(in_reset)
	    data <= PRBS_SEED;
      else 
        if(in_enable)
	      data <= {data[NB_PRBS-2 -: NB_PRBS-1], data[PRBS_HIGH_ORDER-1] ^ data[PRBS_LOW_ORDER-1]};
        else
          data <= data;
   end

   
endmodule // prbsx


