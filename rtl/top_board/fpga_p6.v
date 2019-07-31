/*-----------------------------------------------------------------------------
-- Archivo       : fpga_p6.v
-- Organizacion  : Fundacion Fulgor 
-------------------------------------------------------------------------------
-- Descripcion   : Top level de implementacion
-------------------------------------------------------------------------------
-- Autor         : Ariel Pola
-------------------------------------------------------------------------------*/

//`include "/home/edgardo/Nube/MEGA/Facultad/DDA/TPfinal/DDAfinal/rtl/top_board/fpga_files.v"

module fpga
  (
   out_leds_rgb0,
   out_leds_rgb1,
   out_leds_rgb2,
   out_leds_rgb3,
   out_leds,
   out_tx_uart,
   in_rx_uart,
   in_reset,
   i_switch,
   clk100
   );

   ///////////////////////////////////////////
   // Parameter
   ///////////////////////////////////////////
   parameter NB_GPIOS         = `NB_GPIOS;
   parameter NB_LEDS          = `NB_LEDS;

   parameter NB_ENABLE_RX          = `NB_ENABLE_RX;
   parameter NB_ENABLE_TOTAL       = `NB_ENABLE_TOTAL;

   parameter NB_DATA_RAM_LOG       = `NB_DATA_RAM_LOG;
   parameter NB_ADDR_RAM_LOG       = `NB_ADDR_RAM_LOG;
   parameter NB_LOG_READ_DEVICES   = `NB_LOG_READ_DEVICES;
   parameter NB_DEVICES            = `NB_DEVICES;

   parameter INIT_FILE             = `INIT_FILE;

   parameter NB_PRBS         = `NB_PRBS        ;
   parameter PRBS_LOW_ORDER  = `PRBS_LOW_ORDER ;
   parameter PRBS_HIGH_ORDER = `PRBS_HIGH_ORDER;
   parameter PRBS_SEED       = `PRBS_SEED_I    ;

   parameter NUM_COEFF_CH     = `NUM_COEFF_CH     ;
   parameter NBI_COEFF_CH     = `NBI_COEFF_CH     ;
   parameter NBF_COEFF_CH     = `NBF_COEFF_CH     ;
   parameter NB_LOG2_COEFF_CH = `NB_LOG2_COEFF_CH ;

   parameter NB_STEP_MU       = 8;

   localparam NBI_FIR_OUT     = NBI_COEFF_CH + NB_LOG2_COEFF_CH;
   localparam NBF_FIR_OUT     = NBF_COEFF_CH;
   localparam NB_FIR_OUT      = NBI_FIR_OUT + NBF_FIR_OUT;
   localparam NB_COEFF_CH     = NBI_COEFF_CH + NBF_COEFF_CH;

   ///////////////////////////////////////////
   // Ports
   ///////////////////////////////////////////
   output wire [NB_LEDS - 1 : 0]                     out_leds;
   output [3 - 1 : 0]                                out_leds_rgb0;
   output [3 - 1 : 0]                                out_leds_rgb1;
   output [3 - 1 : 0]                                out_leds_rgb2;
   output [3 - 1 : 0]                                out_leds_rgb3;

   output wire                                       out_tx_uart;
   input wire                                        in_rx_uart;
   input wire                                        in_reset;
   input wire [4 - 1 : 0]                            i_switch;

   input                                             clk100;

   ///////////////////////////////////////////
   // Vars
   ///////////////////////////////////////////
   wire [NB_GPIOS                 - 1 : 0]           gpo0;
   wire [NB_GPIOS                 - 1 : 0]           gpi0;

   wire                                              locked;

   wire                                              enable0;
   wire                                              enable1;
   wire                                              enable2;
   wire                                              enable3;

   wire                                              soft_reset;

   wire [NB_GPIOS                 - 1 : 0]           rf_log_capture_data;

   wire [NB_ENABLE_TOTAL          - 1 : 0]           rf_enables_module;

   wire [(NB_DATA_RAM_LOG*2)      - 1 : 0]           log_data_from_ram;
   wire                                              log_out_full_from_ram;

   wire                                              log_in_ram_run_from_micro;
   wire [NB_ADDR_RAM_LOG          - 1 : 0]           log_read_addr_from_micro;
   wire                                              log_read_upper_low;
   wire [NB_DEVICES               - 1 : 0]           log_read_sel_device;

   wire [NB_LOG_READ_DEVICES      - 1 : 0]           log_read_devices;
   wire                                              clockdsp;
   wire                                              connect_prbs_to_ch;

   wire [NB_FIR_OUT - 1 : 0]                         connect_ch_to_dsp;

   reg [NUM_COEFF_CH*NB_COEFF_CH - 1 : 0]            prmt_coeff_channel;
   reg [NB_STEP_MU -1 : 0]                           step_mu;


   ///////////////////////////////////////////
   // MicroBlaze
   ///////////////////////////////////////////
   design_1
     u_micro
       (.clock100         (clockdsp    ),  // Clock aplicacion
        .gpio_rtl_tri_o   (gpo0        ),  // GPIO
        .gpio_rtl_tri_i   (gpi0        ),  // GPIO
        .reset            (in_reset    ),  // Hard Reset
        .sys_clock        (clk100      ),  // Clock de FPGA
        .o_lock_clock     (locked      ),  // Senal Lock Clock
        .usb_uart_rxd     (in_rx_uart  ),  // UART
        .usb_uart_txd     (out_tx_uart )   // UART
        );

   ///////////////////////////////////////////
   // Leds
   ///////////////////////////////////////////
   assign out_leds[0] = locked;
   assign out_leds[1] = ~in_reset;
   assign out_leds[2] = soft_reset;
   assign out_leds[3] = log_out_full_from_ram & log_in_ram_run_from_micro;

   assign out_leds_rgb0[0] = enable0;
   assign out_leds_rgb0[1] = 1'b0;
   assign out_leds_rgb0[2] = 1'b0;

   assign out_leds_rgb1[0] = enable1;
   assign out_leds_rgb1[1] = 1'b0;
   assign out_leds_rgb1[2] = 1'b0;

   assign out_leds_rgb2[0] = 1'b0;
   assign out_leds_rgb2[1] = enable2;
   assign out_leds_rgb2[2] = 1'b0;

   assign out_leds_rgb3[0] = 1'b0;
   assign out_leds_rgb3[1] = 1'b0;
   assign out_leds_rgb3[2] = enable3;


   ///////////////////////////////////////////
   // Top Phy
   ///////////////////////////////////////////


   ///////////////////////////////////////////
   // Register File
   ///////////////////////////////////////////
   assign {enable3,
           enable2,
           enable1,
           enable0}              = rf_enables_module;

   assign {log_read_sel_device,
           log_read_upper_low,
           log_read_addr_from_micro} = log_read_devices;

   register_file
     u_register_file
       (
        .in_log_capture_data   (log_data_from_ram),
        .out_soft_reset        (soft_reset),
        .out_enables_module    (rf_enables_module),

        // Logs
        .log_ram_run_from_micro (log_in_ram_run_from_micro),
        .log_read_devices       (log_read_devices),

        .out_rf_to_micro_data  (gpi0),
        .in_micro_to_rf_data   (gpo0),
        .in_reset              (~in_reset),
        .clock                 (clockdsp)
        );

   // Generador de bits
   prbsx
     #(
       .NB_PRBS         (NB_PRBS        ),
       .PRBS_LOW_ORDER  (PRBS_LOW_ORDER ),
       .PRBS_HIGH_ORDER (PRBS_HIGH_ORDER),
       .PRBS_SEED       (PRBS_SEED      )
	     )
   u_prbsx
     (
      .out_data (connect_prbs_to_ch),
      .in_enable(enable0),
      .in_reset (soft_reset),
      .clock    (clockdsp)
      );

   always@(posedge clockdsp) begin
      if(i_switch[1:0]==2'b00)
        prmt_coeff_channel <= {8'd0,8'd0,8'd0,8'd127,8'd0,8'd0,8'd0};
      else if(i_switch[1:0]==2'b01)
        prmt_coeff_channel <= {8'd0,8'd0,8'd31,8'd124,8'd0,8'd0,8'd0};
      else if(i_switch[1:0]==2'b10)
        prmt_coeff_channel <= {8'd0,8'd0,8'd31,8'd124,8'd12,8'd0,8'd0};
      else
        prmt_coeff_channel <= {8'd0,8'd22,8'd56,8'd112,8'd11,8'd0,8'd0};
   end

   always@(posedge clockdsp) begin
      if(i_switch[3:2]==2'b00)
        step_mu <= {8'b0000_0000};
      else if(i_switch[3:2]==2'b01)
        step_mu <= {8'b0000_0001};
      else if(i_switch[3:2]==2'b10)
        step_mu <= {8'b0000_0100};
      else
        step_mu <= {8'b0001_0000};
   end

   fir_channel
     #(
       .NUM_COEFF_CH      (NUM_COEFF_CH     ),
       .NBI_COEFF_CH      (NBI_COEFF_CH     ),
       .NBF_COEFF_CH      (NBF_COEFF_CH     ),
       .NB_LOG2_COEFF_CH  (NB_LOG2_COEFF_CH )
       )
   u_fir_channel
     (
      .o_dot_product_ch   (connect_ch_to_dsp ),
      .i_fir_channel_bits (connect_prbs_to_ch),
      .prmt_coeff_channel (prmt_coeff_channel),
      .clock              (clockdsp          )
      );


   ///////////////////////////////////////////
   // Modulo BRAM y FSM
   ///////////////////////////////////////////
   
    dsp dsp_inst
    (
        .clockdsp           (clockdsp                 ), // Clock,
        .soft_reset         (soft_reset               ),  // Reset desde el micro,
        .rf_enables_module  (rf_enables_module        ),
        .connect_ch_to_dsp  (connect_ch_to_dsp        ), // Datos a ecualizar            s(11,7),
        .step_mu            (step_mu                  ), // Paso de adaptacion           u(8,7),
    
        // Logger
        .log_in_ram_run_from_micro  (log_in_ram_run_from_micro), // Inicio de logueo             1bit,
        .log_read_addr_from_micro   (log_read_addr_from_micro ), // Direccion de lectura de BRAM 15bits,
        .log_out_full_from_ram      (log_out_full_from_ram    ), // Memoria completa             1bit
        .log_data_from_ram          (log_data_from_ram        )  // Datos logueados              32bits
    );

   /*-----------------------------------------------------------
   <module> #(
    .<param>   (NB_COUNT          ), // NB del contador       32 bits
    .<param>   (NB_ADDR_RAM_LOG   ), // Longitud de memoria   15bits
    .<param>   (NB_DATA_RAM_LOG*2 ), // Ancho de memoria      32bits
	  )
   u_<module> (
    .o_<port>     (log_data_from_ram        ), // Datos logueados              32bits
    .o_<port>     (log_out_full_from_ram    ), // Memoria completa             1bit

    .i_<port>     (log_in_ram_run_from_micro), // Inicio de logueo             1bit
    .i_<port>     (log_read_addr_from_micro ), // Direccion de lectura de BRAM 15bits

    .i_<port>     (connect_ch_to_dsp        ), // Datos a ecualizar            s(11,7)
    .i_<port>     (step_mu                  ), // Paso de adaptacion           u(8,7)

    .clock        (clockdsp                 ), // Clock
    .cpu_reset    (soft_reset               )  // Reset desde el micro
    );
    -----------------------------------------------------------*/

endmodule // fpga
