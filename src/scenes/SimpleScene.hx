package scenes;

import js.html.Float32Array;
import milkshake.assets.SpriteSheets;
import milkshake.components.input.Key;
import milkshake.core.DisplayObject;
import milkshake.core.Entity;
import milkshake.core.Graphics;
import milkshake.core.Sprite;
import milkshake.game.scene.camera.CameraPresets;
import milkshake.game.scene.Scene;
import milkshake.math.Vector2;
import milkshake.Milkshake;
import milkshake.utils.Color;
import milkshake.utils.Globals;
import motion.easing.Elastic;
import pixi.core.textures.Texture;

using milkshake.utils.TweenUtils;

class Tile extends DisplayObject
{
	public var verticies(default, null):Array<Vector2>;
	public var uvs(default, null):Array<Vector2>;
	public var indicies(default, null):Array<Int>;

	public function new()
	{
		super();

		verticies = [
			new Vector2(0, 0),
			new Vector2(100, 0),
			new Vector2(100, 100),
			new Vector2(0, 100)
		];

		uvs = [
			new Vector2(0, 0),
			new Vector2(1, 0),
			new Vector2(1, 1),
			new Vector2(0, 1)
		];

		indicies = [
			0,
			1,
			2,

			0,
			2,
			3
		];

		var graphic = new Graphics();

		graphic.graphics.beginFill(Color.White);
		graphic.graphics.drawCircle(0, 0, 3);
		graphic.graphics.drawCircle(100, 0, 3);
		graphic.graphics.drawCircle(100, 100, 3);
		graphic.graphics.drawCircle(0, 100, 3);

		addNode(graphic);
	}
}

class SimpleScene extends Scene
{
	public function new()
	{
		super("TestScene", [ "assets/images/grass.png" ], CameraPresets.DEFAULT, Color.Tomato);
	}

	var tiles:Array<Array<Tile>> = [[]];

	function generateMap()
	{
		var list = [];

		for (x in 0 ... 10)
		{
			tiles[x] = [];

			for (y in 0 ... 10)
			{
				var tile  = new Tile();

				tile.x = x * 100;
				tile.y = y * 100;

				tiles[x][y] = tile;

				list.push(tile);
				addNode(tile);
			}
		}

		var verticies = [];

		// list.reverse();

		for(tile in list)
		{
			for(vert in tile.verticies)
			{
				verticies.push(vert.x + tile.x);
				verticies.push(vert.y + tile.y);
			}
		}

		var indicies = [];

		for(tile in list)
		{
			for(indie in tile.indicies)
			{

				indicies.push((list.indexOf(tile) * 4 ) + indie);
			}
		}

		var uvs = [];

		for(tile in list)
		{
			for(uv in tile.uvs)
			{
				uvs.push(uv.x);
				uvs.push(uv.y);
			}
		}

		var mesh = new pixi.mesh.Mesh(
			Texture.fromImage("assets/images/grass.png"), 
			new Float32Array(verticies),
			new Float32Array(uvs),
			new js.html.Int16Array(indicies),
			1
		);

		displayObject.addChildAt(mesh, 1);
	}

	override public function create():Void
	{
		super.create();

		generateMap();


		
	}

	override public function update(deltaTime:Float):Void
	{
		super.update(deltaTime);
	}
}