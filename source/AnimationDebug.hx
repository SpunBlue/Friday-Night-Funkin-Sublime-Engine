package;

import sys.ssl.Key;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
	*DEBUG MODE
 */
class AnimationDebug extends MusicBeatState
{
	var bf:Boyfriend;
	var dad:Character;
	var char:Character;
	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var isDad:Bool = true;
	var daAnim:String = 'spooky';
	var camFollow:FlxObject;

	var tempExit:Bool = false;
	var exitText:FlxText;

	public function new(daAnim:String = 'spooky')
	{
		super();
		this.daAnim = daAnim;
	}

	override function create()
	{
		FlxG.sound.music.stop();

		var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0.5, 0.5);
		add(gridBG);

		if (daAnim == 'bf')
			isDad = false;

		if (isDad)
		{
			dad = new Character(0, 0, daAnim);
			dad.screenCenter();
			dad.debugMode = true;
			add(dad);

			char = dad;
		}
		else
		{
			bf = new Boyfriend(0, 0);
			bf.screenCenter();
			bf.debugMode = true;
			add(bf);

			char = bf;
		}

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);

		textAnim = new FlxText(300, 16);
		textAnim.size = 26;
		textAnim.scrollFactor.set();
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		FlxG.camera.follow(camFollow);

		exitText = new FlxText(0, 0, FlxG.width, "Are you sure you want to exit? This does not save your progress. Press BACK to exit.");
		exitText.setFormat(null, 16, FlxColor.RED, "center");
		exitText.scrollFactor.set(0, 0);
		exitText.visible = false;
		add(exitText);

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void
	{
		var daLoop:Int = 0;

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.scrollFactor.set();
			text.color = FlxColor.BLUE;
			dumbTexts.add(text);

			if (pushList)
				animList.push(anim);

			daLoop++;
		}
	}

	function updateTexts():Void
	{
		dumbTexts.forEach(function(text:FlxText)
		{
			text.kill();
			dumbTexts.remove(text, true);
		});
	}

	override function update(elapsed:Float)
	{
		textAnim.text = char.animation.curAnim.name;

		if (FlxG.keys.justPressed.E)
			FlxG.camera.zoom += 0.25;
		if (FlxG.keys.justPressed.Q)
			FlxG.camera.zoom -= 0.25;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90;
			else
				camFollow.velocity.x = 0;
		}
		else
		{
			camFollow.velocity.set();
		}

		#if desktop
		if (controls.UP_P && !FlxG.keys.anyPressed([SHIFT]))
		{
			curAnim -= 1;
		}

		if (controls.DOWN_P && !FlxG.keys.anyPressed([SHIFT]))
		{
			curAnim += 1;
		}
		#elseif mobile
		if (controls.ACCEPT)
			{
				curAnim += 1;
			}
		#end

		if (curAnim < 0)
			curAnim = animList.length - 1;

		if (curAnim >= animList.length)
			curAnim = 0;

		#if mobile
		if (controls.ACCEPT){
			char.playAnim(animList[curAnim]);

			updateTexts();
			genBoyOffsets(false);
		}
		#elseif desktop
		if (controls.UP_P)
			{
				char.playAnim(animList[curAnim]);
	
				updateTexts();
				genBoyOffsets(false);
			}
	
			if (controls.DOWN_P)
			{
				char.playAnim(animList[curAnim]);
	
				updateTexts();
				genBoyOffsets(false);
			}
		#end

		var upP = controls.UP_P;
		var rightP = controls.RIGHT_P;
		var downP = controls.DOWN_P;
		var leftP = controls.LEFT_P;

		var holdShift = FlxG.keys.pressed.SHIFT;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;

		#if desktop
		if (upP && FlxG.keys.anyPressed([SHIFT]) || rightP && FlxG.keys.anyPressed([SHIFT]) || downP && FlxG.keys.anyPressed([SHIFT]) || leftP && FlxG.keys.anyPressed([SHIFT])){
			{
				updateTexts();
				if (upP)
					char.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
				if (downP)
					char.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
				if (leftP)
					char.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
				if (rightP)
					char.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;
	
				updateTexts();
				genBoyOffsets(false);
				char.playAnim(animList[curAnim]);
			}
		}
		#elseif mobile
		if (upP || rightP || downP || leftP){
			{
				updateTexts();
				if (upP)
					char.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
				if (downP)
					char.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
				if (leftP)
					char.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
				if (rightP)
					char.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;
	
				updateTexts();
				genBoyOffsets(false);
				char.playAnim(animList[curAnim]);
			}
		}
		#end

		super.update(elapsed);

		if (controls.BACK && !tempExit){
			tempExit = true;
			exitText.visible = true;
		}
		else if (controls.BACK && tempExit){
			FlxG.switchState(new MainMenuState());
		}
	}
}
