require 'rexml/document'
require_relative 'BarBase'

module SVG
  module Graph
    # === Create presentation quality SVG horitonzal bar graphs easily
    #
    # = Synopsis
    #
    #   require 'SVG/Graph/BarHorizontal'
    #
    #   fields = %w(Jan Feb Mar)
    #   data_sales_02 = [12, 45, 21]
    #
    #   graph = SVG::Graph::BarHorizontal.new({
    #     :height => 500,
    #     :width => 300,
    #     :fields => fields,
    #   })
    #
    #   graph.add_data({
    #     :data => data_sales_02,
    #     :title => 'Sales 2002',
    #   })
    #
    #   print "Content-type: image/svg+xml\r\n\r\n"
    #   print graph.burn
    #
    # = Description
    #
    # This object aims to allow you to easily create high quality
    # SVG horitonzal bar graphs. You can either use the default style sheet
    # or supply your own. Either way there are many options which can
    # be configured to give you control over how the graph is
    # generated - with or without a key, data elements at each point,
    # title, subtitle etc.
    #
    # = Examples
    #
    # * http://germane-software.com/repositories/public/SVG/test/test.rb
    #
    # = See also
    #
    # * SVG::Graph::Graph
    # * SVG::Graph::Bar
    # * SVG::Graph::Line
    # * SVG::Graph::Pie
    # * SVG::Graph::Plot
    # * SVG::Graph::TimeSeries
    #
    # == Author
    #
    # Sean E. Russell <serATgermaneHYPHENsoftwareDOTcom>
    #
    # Copyright 2004 Sean E. Russell
    # This software is available under the Ruby license[LICENSE.txt]
    #
    class BarHorizontal < BarBase
      # In addition to the defaults set in BarBase::set_defaults, sets
      # [rotate_y_labels] true
      # [show_x_guidelines] true
      # [show_y_guidelines] false
      def set_defaults
        super
        init_with(
          :rotate_y_labels    => true,
          :show_x_guidelines  => true,
          :show_y_guidelines  => false
        )
        # self.right_align = self.right_font = 1
      end

      protected

      def get_x_labels
        maxvalue = max_value
        minvalue = min_value
        range = maxvalue  - minvalue
        unrounded_tick_size = range / 10
        x = (Math.log10(unrounded_tick_size) - 1).ceil
        pow10x = 10 ** x
        @x_scale_division = (unrounded_tick_size / pow10x).ceil * pow10x

        @x_scale_division = scale_divisions if scale_divisions

        if scale_integers
          @x_scale_division = @x_scale_division < 1 ? 1 : @x_scale_division.round
        end

        rv = []
        if maxvalue%@x_scale_division != 0
          maxvalue = maxvalue + @x_scale_division
        end
        if minvalue < 0
          minvalue = @override_minvalue = -(@x_scale_division * (minvalue.abs / @x_scale_division).ceil)
        end
        minvalue.step( maxvalue, @x_scale_division ) {|v| rv << separate_comma(v)}
        return rv
      end

      def get_y_labels
        @config[:fields]
      end

      def y_label_offset( height )
        height / -2.0
      end

      def draw_data
        minvalue = min_value
        fieldheight = field_height * 0.8

        bargap = bar_gap ? (fieldheight < 10 ? fieldheight / 2 : 10) : 0

        bar_height = fieldheight - bargap
        bar_height /= @data.length if stack == :side
        y_mod = (bar_height / 2) + (font_size / 2)

        field_count = 1
        @config[:fields].each_index { |i|
          dataset_count = 0
          for dataset in @data
            value = dataset[:data][i]

            top = @graph_height - (field_height * field_count) + bargap
            top += (field_height/@data.length * 0.2) * dataset_count
            top += (bar_height * dataset_count) if stack == :side
            # cases (assume 0 = +ve):
            #   value  min  length          left
            #    +ve   +ve  value.abs - min minvalue.abs
            #    +ve   -ve  value.abs - 0   minvalue.abs
            #    -ve   -ve  value.abs - 0   minvalue.abs + value
            min = @override_minvalue ? @override_minvalue : minvalue
            length = (value.abs - (min > 0 ? min : 0))/@x_scale_division.to_f * field_width
            left = (min.abs + (value < 0 ? value : 0))/@x_scale_division.to_f * field_width

            @graph.add_element( "rect", {
              "x" => left.to_s,
              "y" => top.to_s,
              "width" => length.to_s,
              "height" => bar_height.to_s,
              "class" => "fill#{dataset_count+1}"
            })

            make_datapoint_text(left+length+5, top+y_mod, dataset[:data][i], "text-anchor: start; ")
            # number format shall not apply to popup (use .to_s conversion)
            add_popup(left+length, top+y_mod , dataset[:data][i].to_s)
            dataset_count += 1
          end
          field_count += 1
        }
      end
    end
  end
end
