import format.SVG;
import sys.io.File;

class Icon
{
	public static function fromSvg(path:String, width:Int=32, height:Int=32)
	{
		var svg = new SVG(File.getContent(path));
		var shape = new flash.display.Shape();
		svg.render(shape.graphics, 0, 0, width, height);

		var bitmapData = new flash.display.BitmapData(width, height, true, 0x00FFFFFF);
		bitmapData.draw(shape);
		return bitmapData.encode("png");
	}
}
