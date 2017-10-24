package scenes;

import js.html.Float32Array;
import js.html.Int16Array;
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
import noisehx.Perlin;
import pixi.core.textures.Texture;
import pixi.mesh.Mesh;

using milkshake.utils.TweenUtils;

class Voxel extends Entity
{
	public var index:Int = -1;

	public function new(position:Vector2)
	{
		super();

		this.position = position;
	}
}

class ControleVoxel extends Voxel
{
	public var value:Float;
	public var active:Bool;
	public var above:Voxel;
	public var right:Voxel;

	public function new(position:Vector2, value:Float, _size:Float)
	{
		super(position);

		this.value = value;
		this.active = value > 0.5;

		above = new Voxel(new Vector2(position.x, position.y + (_size / 2)));
		right = new Voxel(new Vector2(position.x + (_size / 2), position.y));
	}
}

class Square extends Entity
{
	public var topLeft:ControleVoxel;
	public var topRight:ControleVoxel;
	public var bottomLeft:ControleVoxel;
	public var bottomRight:ControleVoxel;

	public var centreTop:Voxel;
	public var centreRight:Voxel;
	public var centreBottom:Voxel;
	public var centreLeft:Voxel;

	public var config:Int = 0;

	public function new(topLeft:ControleVoxel, topRight:ControleVoxel, bottomRight:ControleVoxel, bottomLeft:ControleVoxel)
	{
		super();

		this.topLeft = topLeft;
		this.topRight = topRight;
		this.bottomRight = bottomRight;
		this.bottomLeft = bottomLeft;

		this.centreTop = topLeft.right;
		this.centreRight = bottomRight.above;
		this.centreBottom = bottomLeft.right;
		this.centreLeft = bottomLeft.above;

		this.refresh();
	}

	public function refresh()
	{
		this.config = 0;
		if(topLeft.active) this.config += 8;
		if(topRight.active) this.config += 4;
		if(bottomRight.active) this.config += 2;
		if(bottomLeft.active) this.config += 1;

		topLeft.index = -1;
		topRight.index = -1;
		bottomRight.index = -1;
		bottomLeft.index = -1;
		centreTop.index = -1;
		centreRight.index = -1;
		centreBottom.index = -1;
		centreLeft.index = -1;
	}
}

class VoxelWorld 
{
	public var noise:Perlin;

	public var squares:Array<Array<Square>> = [[]];
	var width:Int;
	var height:Int;
	public function new(width:Int, height:Int, size:Float)
	{
		this.width = width;
		this.height = height;
		
		noise = new Perlin();

		var controlVoxels:Array<Array<ControleVoxel>> = [[]];

		for (x in 0 ... width)
		{
			controlVoxels[x] = [];

			for (y in 0 ... height)
			{
				var position = new Vector2(x * size + (size / 2), y * size + (size / 2));

				controlVoxels[x][y] = new ControleVoxel(position, noise.noise2d(x / 10, y / 10) + 1 / 2, size);
			}
		}

		for (x in 0 ... width - 1)
		{
			squares[x] = [];

			for (y in 0 ... height - 1)
			{
				squares[x][y] = new Square(controlVoxels[x][y + 1],
										   controlVoxels[x + 1][y + 1], 
										   controlVoxels[x + 1][y],
										   controlVoxels[x][y]);
			}
		}
	}

	public function refresh()
	{
		for(squareArray in squares)
		{
			for(square in squareArray)
			{
				square.refresh();
			}
		}
	}
}

class VoxelScene extends Scene
{
	public static inline var XCOUNT:Int = 100;
	public static inline var YCOUNT:Int = 100;

	public static inline var SIZE:Int = 10;

	var world:VoxelWorld;

	var vertices:Array<Vector2> = [];
	var triangles:Array<Int> = [];

	var mesh:Mesh;

	public function new()
	{
		super("TestScene", [ "assets/images/grass.png" ], CameraPresets.DEFAULT, Color.Tomato);
	}

	function generateMap()
	{
		var graphics = new Graphics();
		graphics.begin(Color.Black);
		graphics.graphics.lineStyle(1, Color.Black, 0.5);

		world = new VoxelWorld(XCOUNT, YCOUNT, SIZE);

		for (x in 0 ... XCOUNT)
		{
			for (y in 0 ... YCOUNT)
			{
				graphics.graphics.lineStyle(1, Color.Black);

				graphics.graphics.moveTo((SIZE / 2) + 0, (SIZE / 2) + y * SIZE);
				graphics.graphics.lineTo((SIZE / 2) + (XCOUNT - 1) * SIZE, (SIZE / 2) + y * SIZE);

				graphics.graphics.moveTo((SIZE / 2) + x * SIZE, (SIZE / 2) + 0);
				graphics.graphics.lineTo((SIZE / 2) + x * SIZE, (SIZE / 2) + (YCOUNT - 1) * SIZE);
			}
		}

		// for (x in 0 ... XCOUNT - 1)
		// {
		// 	for (y in 0 ... YCOUNT - 1)
		// 	{
		// 		graphics.graphics.lineStyle(0);

		// 		var tile = world.squares[x][y];

		// 		var szi = 10;

		// 		graphics.graphics.beginFill(Color.Black, tile.topLeft.active ? 1 : 0.2);
		// 		graphics.graphics.drawRect(tile.topLeft.x - (szi / 2), tile.topLeft.y - (szi / 2), szi, szi);

		// 		graphics.graphics.beginFill(Color.Black, tile.topRight.active ? 1 : 0.2);
		// 		graphics.graphics.drawRect(tile.topRight.x - (szi / 2), tile.topRight.y - (szi / 2), szi, szi);

		// 		graphics.graphics.beginFill(Color.Black, tile.bottomLeft.active ? 1 : 0.2);
		// 		graphics.graphics.drawRect(tile.bottomLeft.x - (szi / 2), tile.bottomLeft.y - (szi / 2), szi, szi);

		// 		graphics.graphics.beginFill(Color.Black, tile.bottomRight.active ? 1 : 0.2);
		// 		graphics.graphics.drawRect(tile.bottomRight.x - (szi / 2), tile.bottomRight.y - (szi / 2), szi, szi);



		// 		var centerSize = 3;
		// 		graphics.graphics.beginFill(Color.White, 1);
		// 		graphics.graphics.drawRect(tile.centreTop.x - (centerSize / 2), tile.centreTop.y - (centerSize / 2), centerSize, centerSize);
		// 		graphics.graphics.drawRect(tile.centreRight.x - (centerSize / 2), tile.centreRight.y - (centerSize / 2), centerSize, centerSize);
		// 		graphics.graphics.drawRect(tile.centreBottom.x - (centerSize / 2), tile.centreBottom.y - (centerSize / 2), centerSize, centerSize);
		// 		graphics.graphics.drawRect(tile.centreLeft.x - (centerSize / 2), tile.centreLeft.y - (centerSize / 2), centerSize, centerSize);
		// 	}
		// }

		// addNode(graphics);

		

		mesh = new Mesh(
			Texture.fromImage("assets/images/dirt.png"), 
			new Float32Array([]),
			new Float32Array([]),
			new Int16Array([]),
			1
		);

		displayObject.addChildAt(mesh, 1);

		regenerateMesh();


	}

	function regenerateMesh()
	{
		vertices = [];
		triangles = [];

		for (x in 0 ... XCOUNT - 1)
		{
			for (y in 0 ... YCOUNT - 1)
			{
				triangluateSquare(world.squares[x][y]);
			}
		}


		var verticies = [];
		var uvs:Array<Float> = [];

		for(vert in vertices)
		{
			verticies.push(vert.x);
			verticies.push(vert.y);

			uvs.push(vert.x / 50);
			uvs.push(vert.y / 50);
		}

		mesh.indices = new Int16Array(triangles);
		mesh.vertices = new Float32Array(verticies);
		mesh.uvs = new Float32Array(uvs);
		mesh.dirty = true;
	}

	function smooth(square:Square, a:Int, b:Int)
	{
		var iso:Float = 1;

		var aVoxel:Voxel = null;
		if(a == 0) aVoxel = square.centreLeft;
		if(a == 1) aVoxel = square.bottomRight;
		if(a == 2) aVoxel = square.topLeft;
		if(a == 3) aVoxel = square.topRight;

		var bVoxel:Voxel = null;
		if(b == 0) bVoxel = square.bottomLeft;
		if(b == 1) bVoxel = square.bottomRight;
		if(b == 2) bVoxel = square.topLeft;
		if(b == 3) bVoxel = square.topRight;

		var aValue:Float = 1;
		var bValue:Float = 1;

		var mu:Float = 0;
		var p:Vector2 = new Vector2();
 
		if (Math.abs(iso - aValue) < 0.00001)
			return aVoxel.position;

		if (Math.abs(iso - bValue) < 0.00001)
			return bVoxel.position;

		if (Math.abs(aValue - bValue) < 0.00001)
			return aVoxel.position;
 
		mu = (iso - aValue) / (bValue - aValue);
		p.x = aVoxel.x + mu * (bVoxel.x - aVoxel.x);
		p.y = aVoxel.y + mu * (bVoxel.y - aVoxel.y);
		
		return p;
	}

	function lerp(position:Vector2, a:ControleVoxel, b:ControleVoxel)
	{
		var p:Vector2 = new Vector2();

		var mu:Float = (1 - a.value) / (b.value - a.value);

		p.x = position.x + ((b.x - a.x) * mu);
		p.y = position.y + ((b.y - a.y) * mu);

		return p;
	}

	function triangluateSquare(square:Square)
	{
		switch(square.config)
		{
			case 1: meshFromPoints([ square.centreBottom, square.bottomLeft, square.centreLeft ],
								   [ lerp(square.centreBottom.position, square.bottomLeft, square.bottomRight), square.bottomLeft.position, lerp(square.centreLeft.position, square.topLeft, square.bottomLeft) ]);

			case 2: meshFromPoints([ square.centreRight, square.bottomRight, square.centreBottom ],
								   [ square.centreRight.position, square.bottomRight.position, square.centreBottom.position ]);

			case 4: meshFromPoints([ square.centreTop, square.topRight, square.centreRight ],
								   [ square.centreTop.position, square.topRight.position, square.centreRight.position ]);

			case 8: meshFromPoints([ square.topLeft, square.centreTop, square.centreLeft ],
								   [ square.topLeft.position, square.centreTop.position, square.centreLeft.position ]);




			case 3: meshFromPoints([ square.centreRight, square.bottomRight, square.bottomLeft, square.centreLeft ],
								   [ square.centreRight.position, square.bottomRight.position, square.bottomLeft.position, square.centreLeft.position ]);

			case 6: meshFromPoints([ square.centreTop, square.topRight, square.bottomRight, square.centreBottom ],
								   [ square.centreTop.position, square.topRight.position, square.bottomRight.position, square.centreBottom.position ]);

			case 9: meshFromPoints([ square.topLeft, square.centreTop, square.centreBottom, square.bottomLeft ],
								   [ square.topLeft.position, square.centreTop.position, square.centreBottom.position, square.bottomLeft.position ]);

			case 12: meshFromPoints([ square.topLeft, square.topRight, square.centreRight, square.centreLeft ],
								   [ square.topLeft.position, square.topRight.position, square.centreRight.position, square.centreLeft.position ]);


			case 5: meshFromPoints([ square.centreTop, square.topRight, square.centreRight, square.centreBottom, square.bottomLeft, square.centreLeft ],
								   [ square.centreTop.position, square.topRight.position, square.centreRight.position, square.centreBottom.position, square.bottomLeft.position, square.centreLeft.position ]);

			case 10: meshFromPoints([ square.topLeft, square.centreTop, square.centreRight, square.bottomRight, square.centreBottom, square.centreLeft ],
								   [ square.topLeft.position, square.centreTop.position, square.centreRight.position, square.bottomRight.position, square.centreBottom.position, square.centreLeft.position ]);


			case 7: meshFromPoints([ square.centreTop, square.topRight, square.bottomRight, square.bottomLeft, square.centreLeft ],
								   [ square.centreTop.position, square.topRight.position, square.bottomRight.position, square.bottomLeft.position, square.centreLeft.position ]);

			case 11: meshFromPoints([ square.topLeft, square.centreTop, square.centreRight, square.bottomRight, square.bottomLeft ],
								   [ square.topLeft.position, square.centreTop.position, square.centreRight.position, square.bottomRight.position, square.bottomLeft.position ]);

			case 13: meshFromPoints([ square.topLeft, square.topRight, square.centreRight, square.centreBottom, square.bottomLeft ],
								   [ square.topLeft.position, square.topRight.position, square.centreRight.position, square.centreBottom.position, square.bottomLeft.position ]);

			case 14: meshFromPoints([ square.topLeft, square.topRight, square.bottomRight, square.centreBottom, square.centreLeft ],
								   [ square.topLeft.position, square.topRight.position, square.bottomRight.position, square.centreBottom.position, square.centreLeft.position ]);


			case 15: meshFromPoints([ square.topLeft, square.topRight, square.bottomRight, square.bottomLeft ],
								   [ square.topLeft.position, square.topRight.position, square.bottomRight.position, square.bottomLeft.position ]);

		}
	}



	function meshFromPoints(points:Array<Voxel>, positions:Array<Vector2>)
	{
		asignVerts(points, positions);

		if(points.length >= 3) createTri(points[0], points[1], points[2]);
		if(points.length >= 4) createTri(points[0], points[2], points[3]);
		if(points.length >= 5) createTri(points[0], points[3], points[4]);
		if(points.length >= 6) createTri(points[0], points[4], points[5]);
	}

	function asignVerts(nodes:Array<Voxel>, positions:Array<Vector2>)
	{
		for (i in 0 ... nodes.length) {
			if(nodes[i].index == -1) nodes[i].index = vertices.length;

			vertices.push(positions[i]);
		}
	}

	function createTri(nodeA:Voxel, nodeB:Voxel, nodeC:Voxel)
	{
		triangles.push(nodeA.index);
		triangles.push(nodeB.index);
		triangles.push(nodeC.index);
	}

	override public function create():Void
	{
		super.create();

		generateMap();
	}
	var index:Int = 0;
	override public function update(deltaTime:Float):Void
	{
		super.update(deltaTime);

		// index++;

		// if(index > 10)
		// {
		// 	index = 0;
		// 	var x = Math.floor(1 + Math.random() * (XCOUNT - 2));
		// 	var y = Math.floor(1 + Math.random() * (YCOUNT - 2));

		// 	world.squares[x][y].topLeft.active = !world.squares[x][y].topLeft.active;
		// 	world.refresh();

		// 	regenerateMesh();
		// 	trace("Update");
		// }
	}
}