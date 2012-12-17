package provide BLUICEBarcodeView 1.0

package require DCSStringView

class BarcodeView {
    inherit ::itk::Widget

    public method onBarcodeClick { barcode } {
        puts "barcode: $barcode"
    }

    constructor { args } {
        itk_component add barcode {
            DCS::CassetteBarcodeView $itk_interior.b \
            -onClick "$this onBarcodeClick"
        } {
        }
        itk_component add owner {
            DCS::CassetteOwnerView $itk_interior.o \
            -systemIdleOnly 0 \
            -activeClientOnly 0 \
        } {
        }
        pack $itk_component(barcode) -side left -anchor nw
        pack $itk_component(owner)   -side left -anchor nw

		eval itk_initialize $args
    }
}
