/*-----------------------------------------------------------------------------
-- Archivo       : register_file.v
-- Organizacion  : Fundacion Fulgor 
-- Fecha         : 2016-01-06
-------------------------------------------------------------------------------
-- Descripcion   : Register File
-------------------------------------------------------------------------------
-- Autores       : Ariel Pola
-------------------------------------------------------------------------------*/

//`include "../include/ffe_dffe_parameters.v"

module register_file
  (
   out_rf_to_micro_data              ,
   out_soft_reset                    ,
   out_enables_module                ,

   in_log_capture_data               ,

   in_micro_to_rf_data               ,
   in_reset                          ,

   //Logs
   log_ram_run_from_micro            ,
   log_read_devices                  ,

   clock
   );

   ///////////////////////////////////////////
   // Parameter
   ///////////////////////////////////////////
   parameter NBI_AWGN_DATA         = `NBI_AWGN_DATA;
   parameter NBF_AWGN_DATA         = `NBF_AWGN_DATA;
   parameter NB_GPIOS              = `NB_GPIOS;
   parameter NB_ENABLE_TOTAL       = `NB_ENABLE_TOTAL;
   parameter NB_BER_CTRL           = `NB_BER_CTRL;
   parameter NB_MU                 = `NB_MU;
   parameter NB_BETA               = `NB_BETA;
   parameter NB_BER_ERROR          = `NB_BER_ERROR;

   parameter NB_GPIO_DATA          = `NB_GPIO_DATA;
   parameter NB_GPIO_ADDRESS       = `NB_GPIO_ADDRESS;
   parameter NB_LOG_READ_DEVICES   = `NB_LOG_READ_DEVICES;
   
   ///////////////////////////////////////////
   // Localparam
   ///////////////////////////////////////////
   localparam NB_AWGN_DATA    = NBI_AWGN_DATA + NBF_AWGN_DATA;

   ///////////////////////////////////////////
   // Ports
   ///////////////////////////////////////////
   output reg [NB_GPIOS            - 1 : 0] out_rf_to_micro_data ;
   output reg                               out_soft_reset       ;
   output reg [NB_ENABLE_TOTAL     - 1 : 0] out_enables_module   ;

   input [NB_GPIOS                 - 1 : 0] in_log_capture_data  ;

   input [NB_GPIOS                 - 1 : 0] in_micro_to_rf_data  ;
   input                                    in_reset             ;
   input                                    clock                ;

   output reg                               log_ram_run_from_micro;
   output reg [NB_LOG_READ_DEVICES - 1 : 0] log_read_devices;

   ///////////////////////////////////////////
   // Vars
   ///////////////////////////////////////////
   reg [NB_GPIOS - 1 : 0]               from_micro_data;
   wire [NB_GPIO_DATA - 1 : 0]          micro_data;
   wire                                 micro_reg_en;
   wire [NB_GPIO_ADDRESS - 1 : 0]       micro_dir;
   reg [NB_GPIO_ADDRESS - 1 : 0]        gpio_return_select;


  
   assign micro_data   = from_micro_data[22:0];
   assign micro_reg_en = from_micro_data[23];
   assign micro_dir    = from_micro_data[31:24];
   
   always @(posedge clock) begin:crossregs
	  from_micro_data  <= in_micro_to_rf_data;
   end
   
   always @(posedge clock) begin:regs
	    if(in_reset) begin
	       gpio_return_select                 <= {NB_GPIO_ADDRESS{1'd0}};
         out_soft_reset                     <= 1'd1;
         out_enables_module                 <= {NB_ENABLE_TOTAL{1'd0}};

         log_ram_run_from_micro             <= 1'd0;
         log_read_devices                   <= {NB_LOG_READ_DEVICES{1'b0}};
	  end
	  else begin
	     if(micro_reg_en) begin	
	        case(micro_dir)
		        8'd0  : gpio_return_select                 <= micro_data[NB_GPIO_ADDRESS-1:0]  ;
            8'd1  : out_soft_reset                     <= micro_data[0]    ;
            8'd2  : out_enables_module                 <= micro_data[NB_ENABLE_TOTAL-1:0]  ;
            8'd6  : log_ram_run_from_micro             <= micro_data[0];
            8'd7  : log_read_devices                   <= micro_data[NB_LOG_READ_DEVICES-1:0];
            default: gpio_return_select                <= micro_data[NB_GPIO_ADDRESS-1:0]  ;
	        endcase // case (i_from_micro_dir)
	     end
	  end // else: !if(in_reset)
   end // block: regs
   
   always @ (posedge clock) begin
      case(gpio_return_select)
	    8'd0    : out_rf_to_micro_data <= in_log_capture_data;

	    default : out_rf_to_micro_data <= in_log_capture_data;
      endcase // case (gpio_return_select)
   end // always @ (posedge clock)
   
endmodule // register_file
