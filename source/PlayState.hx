package;

import sys.FileSystem;
import openfl.media.Sound;
import sys.io.File;
import openfl.media.Video;
import flixel.input.actions.FlxActionManager.ActionSetJson;
import Controls.Action;
import flixel.math.FlxRandom;
#if desktop
import Discord.DiscordClient;
#end
#if (windows || linux)
import vlc.VideoHandler;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	var halloweenLevel:Bool = false;

	private var vocals:FlxSound;

	private var dad:Character;
	private var gf:Character;
	private var boyfriend:Boyfriend;

	private var notes:FlxTypedGroup<Note>;
	private var unspawnNotes:Array<Note> = [];
	private var noteSplashes:FlxTypedGroup<NoteSplash>;

	private var strumLine:FlxSprite;
	private var curSection:Int = 0;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	private var strumLineNotes:FlxTypedGroup<FlxSprite>;
	private var playerStrums:FlxTypedGroup<FlxSprite>;
	private var cpuStrums:FlxTypedGroup<FlxSprite>;

	private var camZooming:Bool = false;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;
	private var health:Float = 1;
	private var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;
	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	var halloweenBG:FlxSprite;
	var isHalloween:Bool = false;

	var phillyCityLights:FlxTypedGroup<FlxSprite>;
	var phillyTrain:FlxSprite;
	var trainSound:FlxSound;

	var limo:FlxSprite;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:FlxSprite;

	var upperBoppers:FlxSprite;
	var bottomBoppers:FlxSprite;
	var santa:FlxSprite;

	var bgGirls:BackgroundGirls;
	var wiggleShit:WiggleEffect = new WiggleEffect();

	var talking:Bool = true;
	var songScore:Int = 0;
	var misses:Int = 0;
	var sicks:Int = 0;
	var goods:Int = 0;
	var bads:Int = 0;
	var shits:Int = 0;
	var scoreTxt:FlxText;

	var songScrollSpeed:Float = SONG.speed;

	public static var campaignScore:Int = 0;

	var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	var inCutscene:Bool = false;
	var playedEndCutscene:Bool = false;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	var songLength:Float = 1;

	var strumUnderlay:FlxSprite;

	var ogBF = SONG.player1;
	var inPanic = false;

	public static var isMod:Bool = false;
	var events = [];

	var alreadyLoaded:Bool = false;

	public static var secretMode:Bool = false;

	override public function create()
	{
		// A-AA-AAA O E O AH E I O E A-AA-AAA

		trace('ENDCUTSCENE PLAYED? ' + playedEndCutscene);
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		if (FlxG.save.data.downScroll == null)
			FlxG.save.data.downScroll = false;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		switch (SONG.song.toLowerCase())
		{
			case 'tutorial':
				dialogue = [":gf:Hey you're pretty cute.", ':gf:Use the arrow keys to keep up with me singing.', ':bf:Beep!'];
			case 'bopeebo':
				dialogue = [
					'HEY!',
					"You think you can just sing\nwith my daughter like that?",
					"If you want to date her...",
					"You're going to have to go \nthrough ME first!"
				];
			case 'fresh':
				dialogue = ["Not too shabby boy.", ""];
			case 'dadbattle':
				dialogue = [
					"gah you think you're hot stuff?",
					"If you can beat me here...",
					"Only then I will even CONSIDER letting you\ndate my daughter!"
				];
			case 'senpai':
				dialogue = CoolUtil.coolTextFile(Paths.txt('senpai/senpaiDialogue'));
			case 'roses':
				dialogue = CoolUtil.coolTextFile(Paths.txt('roses/rosesDialogue'));
			case 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.txt('thorns/thornsDialogue'));
		}

		#if desktop
		// Making difficulty text for Discord Rich Presence.
		switch (storyDifficulty)
		{
			case 0:
				storyDifficultyText = "Easy";
			case 1:
				storyDifficultyText = "Normal";
			case 2:
				storyDifficultyText = "Hard";
		}

		iconRPC = SONG.player2;

		// To avoid having duplicate images in Discord assets
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end

		noteSplashes = new FlxTypedGroup<NoteSplash>();
		var daSplash = new NoteSplash(100, 100, 0);
		daSplash.alpha = 0;
		noteSplashes.add(daSplash);

		if (FlxG.save.data.liteMode == null){
			FlxG.save.data.liteMode = false;
		}

		if (!FlxG.save.data.liteMode){
			FlxG.camera.bgColor = FlxColor.BLACK;

			
			switch (SONG.song.toLowerCase())
			{
                        case 'spookeez' | 'monster' | 'south': 
                        {
                                curStage = 'spooky';
	                          halloweenLevel = true;

		                  var hallowTex = Paths.getSparrowAtlas('halloween_bg');

	                          halloweenBG = new FlxSprite(-200, -100);
		                  halloweenBG.frames = hallowTex;
	                          halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
	                          halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
	                          halloweenBG.animation.play('idle');
	                          halloweenBG.antialiasing = true;
	                          add(halloweenBG);

		                  isHalloween = true;
		          }
		          case 'pico' | 'blammed' | 'philly': 
                        {
		                  curStage = 'philly';

		                  var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('philly/sky'));
		                  bg.scrollFactor.set(0.1, 0.1);
		                  add(bg);
						
	                	var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city'));
		                  city.scrollFactor.set(0.3, 0.3);
		                  city.setGraphicSize(Std.int(city.width * 0.85));
		                  city.updateHitbox();
		                  add(city);

						  if (!FlxG.save.data.epilepsyMode){
							phillyCityLights = new FlxTypedGroup<FlxSprite>();
							add(phillyCityLights);
						  }

		                  for (i in 0...5)
		                  {
							  if (!FlxG.save.data.epilepsyMode){
		                          var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win' + i));
		                          light.scrollFactor.set(0.3, 0.3);
		                          light.visible = false;
		                          light.setGraphicSize(Std.int(light.width * 0.85));
		                          light.updateHitbox();
		                          light.antialiasing = true;
		                          phillyCityLights.add(light);
							  }
		                  }

		                  var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain'));
		                  add(streetBehind);

	                          phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image('philly/train'));
		                  add(phillyTrain);

		                  trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes'));
		                  FlxG.sound.list.add(trainSound);

		                  // var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

		                  var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image('philly/street'));
	                          add(street);
		          }
		          case 'milf' | 'satin-panties' | 'high':
		          {
		                  curStage = 'limo';
		                  defaultCamZoom = 0.90;

		                  var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('limo/limoSunset'));
		                  skyBG.scrollFactor.set(0.1, 0.1);
		                  add(skyBG);

		                  var bgLimo:FlxSprite = new FlxSprite(-200, 480);
		                  bgLimo.frames = Paths.getSparrowAtlas('limo/bgLimo');
		                  bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
		                  bgLimo.animation.play('drive');
		                  bgLimo.scrollFactor.set(0.4, 0.4);
		                  add(bgLimo);

		                  grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
		                  add(grpLimoDancers);

		                  for (i in 0...5)
		                  {
		                          var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
		                          dancer.scrollFactor.set(0.4, 0.4);
		                          grpLimoDancers.add(dancer);
		                  }

		                  var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic(Paths.image('limo/limoOverlay'));
		                  overlayShit.alpha = 0.5;
		                  // add(overlayShit);

		                  // var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

		                  // FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

		                  // overlayShit.shader = shaderBullshit;

		                  var limoTex = Paths.getSparrowAtlas('limo/limoDrive');

		                  limo = new FlxSprite(-120, 550);
		                  limo.frames = limoTex;
		                  limo.animation.addByPrefix('drive', "Limo stage", 24);
		                  limo.animation.play('drive');
		                  limo.antialiasing = true;

		                  fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('limo/fastCarLol'));
		                  // add(limo);
		          }
		          case 'cocoa' | 'eggnog':
		          {
	                          curStage = 'mall';

		                  defaultCamZoom = 0.80;

		                  var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('christmas/bgWalls'));
		                  bg.antialiasing = true;
		                  bg.scrollFactor.set(0.2, 0.2);
		                  bg.active = false;
		                  bg.setGraphicSize(Std.int(bg.width * 0.8));
		                  bg.updateHitbox();
		                  add(bg);

		                  upperBoppers = new FlxSprite(-240, -90);
		                  upperBoppers.frames = Paths.getSparrowAtlas('christmas/upperBop');
		                  upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
		                  upperBoppers.antialiasing = true;
		                  upperBoppers.scrollFactor.set(0.33, 0.33);
		                  upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
		                  upperBoppers.updateHitbox();
						  if (!FlxG.save.data.noDistractions)
		                  	add(upperBoppers);

		                  var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('christmas/bgEscalator'));
		                  bgEscalator.antialiasing = true;
		                  bgEscalator.scrollFactor.set(0.3, 0.3);
		                  bgEscalator.active = false;
		                  bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
		                  bgEscalator.updateHitbox();
		                  add(bgEscalator);

		                  var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('christmas/christmasTree'));
		                  tree.antialiasing = true;
		                  tree.scrollFactor.set(0.40, 0.40);
		                  add(tree);

		                  bottomBoppers = new FlxSprite(-300, 140);
		                  bottomBoppers.frames = Paths.getSparrowAtlas('christmas/bottomBop');
		                  bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
		                  bottomBoppers.antialiasing = true;
	                          bottomBoppers.scrollFactor.set(0.9, 0.9);
	                          bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
		                  bottomBoppers.updateHitbox();
						  if (!FlxG.save.data.noDistractions)
		                  	add(bottomBoppers);

		                  var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('christmas/fgSnow'));
		                  fgSnow.active = false;
		                  fgSnow.antialiasing = true;
		                  add(fgSnow);

		                  santa = new FlxSprite(-840, 150);
		                  santa.frames = Paths.getSparrowAtlas('christmas/santa');
		                  santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
		                  santa.antialiasing = true;
		                  add(santa);
		          }
		          case 'winter-horrorland':
		          {
		                  curStage = 'mallEvil';
		                  var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('christmas/evilBG'));
		                  bg.antialiasing = true;
		                  bg.scrollFactor.set(0.2, 0.2);
		                  bg.active = false;
		                  bg.setGraphicSize(Std.int(bg.width * 0.8));
		                  bg.updateHitbox();
		                  add(bg);

		                  var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image('christmas/evilTree'));
		                  evilTree.antialiasing = true;
		                  evilTree.scrollFactor.set(0.2, 0.2);
		                  add(evilTree);

		                  var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image("christmas/evilSnow"));
	                          evilSnow.antialiasing = true;
		                  add(evilSnow);
                        }
		          case 'senpai' | 'roses' | 'roses-swagmix':
		          {
		                  curStage = 'school';

		                  // defaultCamZoom = 0.9;

		                  var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/weebSky', 'week6'));
		                  bgSky.scrollFactor.set(0.1, 0.1);
		                  add(bgSky);

		                  var repositionShit = -200;

		                  var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('weeb/weebSchool', 'week6'));
		                  bgSchool.scrollFactor.set(0.6, 0.90);
		                  add(bgSchool);

		                  var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreet', 'week6'));
		                  bgStreet.scrollFactor.set(0.95, 0.95);
		                  add(bgStreet);

		                  var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('weeb/weebTreesBack', 'week6'));
		                  fgTrees.scrollFactor.set(0.9, 0.9);
		                  add(fgTrees);

		                  var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
		                  var treetex = Paths.getPackerAtlas('weeb/weebTrees', 'week6');
		                  bgTrees.frames = treetex;
		                  bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		                  bgTrees.animation.play('treeLoop');
		                  bgTrees.scrollFactor.set(0.85, 0.85);
		                  add(bgTrees);

		                  var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
		                  treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals', 'week6');
		                  treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
		                  treeLeaves.animation.play('leaves');
		                  treeLeaves.scrollFactor.set(0.85, 0.85);
		                  add(treeLeaves);

		                  var widShit = Std.int(bgSky.width * 6);

		                  bgSky.setGraphicSize(widShit);
		                  bgSchool.setGraphicSize(widShit);
		                  bgStreet.setGraphicSize(widShit);
		                  bgTrees.setGraphicSize(Std.int(widShit * 1.4));
		                  fgTrees.setGraphicSize(Std.int(widShit * 0.8));
		                  treeLeaves.setGraphicSize(widShit);

		                  fgTrees.updateHitbox();
		                  bgSky.updateHitbox();
		                  bgSchool.updateHitbox();
		                  bgStreet.updateHitbox();
		                  bgTrees.updateHitbox();
		                  treeLeaves.updateHitbox();

		                  bgGirls = new BackgroundGirls(-100, 190);
		                  bgGirls.scrollFactor.set(0.9, 0.9);

		                if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'roses-swagmix')
	                    {
		                	bgGirls.getScared();
	  					}

		                  bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
		                  bgGirls.updateHitbox();
		                  add(bgGirls);
		          }
		          case 'thorns':
		          {
		                curStage = 'schoolEvil';

		                var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
		                var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

		                var posX = 400;
	                        var posY = 200;

		                var bg:FlxSprite = new FlxSprite(posX, posY);
		                bg.frames = Paths.getSparrowAtlas('weeb/animatedEvilSchool', 'week6');
		                bg.animation.addByPrefix('idle', 'background 2', 24);
		                bg.animation.play('idle');
		                bg.scrollFactor.set(0.8, 0.9);
		                bg.scale.set(6, 6);
		                add(bg);
		          }
				  case 'ugh' | 'guns' | 'stress' | 'ugh-swagmix':{
					  //imagine knowing what you are doing
					defaultCamZoom = 0.7;
					curStage = 'tankStage';

					var bg:FlxSprite = new FlxSprite(-450, -200).loadGraphic(Paths.image('Tankman/tankSky'));
					bg.setGraphicSize(Std.int(bg.width * 1.8));
					bg.antialiasing = true;
					bg.scrollFactor.set(0.9, 0.9);
					bg.active = false;
					add(bg);

					var stageCurtains:FlxSprite = new FlxSprite(-800, -140).loadGraphic(Paths.image('Tankman/tankMountains'));
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 2));
					stageCurtains.updateHitbox();
					stageCurtains.antialiasing = true;
					stageCurtains.scrollFactor.set(0.5, 0.5);
					stageCurtains.active = false;
					add(stageCurtains);

					var stageRuins:FlxSprite = new FlxSprite(-1070, -260).loadGraphic(Paths.image('Tankman/tankRuins'));
					stageRuins.setGraphicSize(Std.int(stageRuins.width * 2));
					stageRuins.updateHitbox();
					stageRuins.antialiasing = true;
					stageRuins.scrollFactor.set(0.5, 0.5);
					stageRuins.active = false;
					add(stageRuins);

					var stageBuildings:FlxSprite = new FlxSprite(-1070, -260).loadGraphic(Paths.image('Tankman/tankBuildings'));
					stageBuildings.setGraphicSize(Std.int(stageBuildings.width * 2));
					stageBuildings.updateHitbox();
					stageBuildings.antialiasing = true;
					stageBuildings.scrollFactor.set(0.5, 0.5);
					stageBuildings.active = false;
					add(stageBuildings);

					var guardTower = new FlxSprite(-300, -100);
					guardTower.frames = Paths.getSparrowAtlas('Tankman/tankWatchtower');
					guardTower.animation.addByPrefix('color', 'watchtower gradient color instance', 24, false);
					guardTower.setGraphicSize(Std.int(guardTower.width * 1.35));
					guardTower.antialiasing = true;
					guardTower.updateHitbox();
					add(guardTower);

					var stageFront:FlxSprite = new FlxSprite(-685, -350).loadGraphic(Paths.image('Tankman/tankGround'));
					stageFront.setGraphicSize(Std.int(stageFront.width * 1.4));
					stageFront.updateHitbox();
					stageFront.antialiasing = true;
					stageFront.scrollFactor.set(0.9, 0.9);
					stageFront.active = false;
					add(stageFront);
				}
		          default:
		          {	
							defaultCamZoom = 0.9;
							curStage = 'stage';
							var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback'));
							bg.antialiasing = true;
							bg.scrollFactor.set(0.9, 0.9);
							bg.active = false;
							add(bg);
  
							var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront'));
							stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
							stageFront.updateHitbox();
							stageFront.antialiasing = true;
							stageFront.scrollFactor.set(0.9, 0.9);
							stageFront.active = false;
							add(stageFront);
  
							var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains'));
							stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
							stageCurtains.updateHitbox();
							stageCurtains.antialiasing = true;
							stageCurtains.scrollFactor.set(1.3, 1.3);
							stageCurtains.active = false;
  
							add(stageCurtains);
		        }
            }	
		}
		else if (FlxG.save.data.liteMode){
			curStage = 'litestage';
			FlxG.camera.bgColor = FlxColor.GRAY;
		}
		
		var gfVersion:String = 'gf';

		switch (curStage)
		{
			case 'limo':
				gfVersion = 'gf-car';
			case 'mall' | 'mallEvil':
				gfVersion = 'gf-christmas';
			case 'school':
				gfVersion = 'gf-pixel';
			case 'schoolEvil':
				gfVersion = 'gf-pixel';
			case 'tankStage':
				if (SONG.song == 'Stress')
					gfVersion = 'picoSpeaker';
				else
					gfVersion = 'tankGF';
		}

		if (curStage == 'limo')
			gfVersion = 'gf-car';

		gf = new Character(400, 130, gfVersion);
		gf.scrollFactor.set(0.95, 0.95);

		dad = new Character(100, 100, SONG.player2);

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		var daCamY:Int = 0;
		var daCamX:Int = 0;

		switch (SONG.player2)
		{
			case 'gf':
				dad.setPosition(gf.x, gf.y);
				gf.visible = false;
				if (isStoryMode)
				{
					camPos.x += 600;
					tweenCamIn();
				}

			case "spooky":
				dad.y += 200;
			case "monster":
				dad.y += 100;
			case 'monster-christmas':
				dad.y += 130;
			case 'dad':
				camPos.x += 400;
			case 'pico':
				camPos.x += 600;
				dad.y += 300;
			case 'parents-christmas':
				dad.x -= 500;
			case 'senpai':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'senpai-angry':
				dad.x += 150;
				dad.y += 360;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case 'spirit':
				dad.x -= 150;
				dad.y += 100;
				camPos.set(dad.getGraphicMidpoint().x + 300, dad.getGraphicMidpoint().y);
			case "tankman":
				dad.y += 240;
				dad.x -= 70;
		}

		boyfriend = new Boyfriend(770, 450, SONG.player1);

		// REPOSITIONING PER STAGE
		switch (curStage)
		{
			case 'limo':
				boyfriend.y -= 220;
				boyfriend.x += 260;

				resetFastCar();
				add(fastCar);

			case 'mall':
				boyfriend.x += 200;

			case 'mallEvil':
				boyfriend.x += 320;
				dad.y -= 80;
			case 'school':
				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			case 'schoolEvil':
				// trailArea.scrollFactor.set();

				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				// evilTrail.changeValuesEnabled(false, false, false, false);
				// evilTrail.changeGraphic()
				add(evilTrail);
				// evilTrail.scrollFactor.set(1.1, 1.1);

				boyfriend.x += 200;
				boyfriend.y += 220;
				gf.x += 180;
				gf.y += 300;
			
			case 'tankStage':
				boyfriend.x +=150;
				dad.x -=60;
				if (SONG.song != 'Stress'){
					gf.x -= 180;
					gf.y -= -10;
				}
				else {//if stress
					gf.x -= 40;
					gf.y -= 100;
				}
		}

		if (!FlxG.save.data.liteMode){
			add(gf);

			// Shitty layering but whatev it works LOL
			if (curStage == 'limo')
				add(limo);
	
			add(dad);
			add(boyfriend);
		}


		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;

		Conductor.songPosition = -5000;

		//Player Strums underlay (idc if this is a dumb way of doing this)
		strumUnderlay = new FlxSprite(690, 0).makeGraphic(445, 720, FlxColor.BLACK);
		strumUnderlay.alpha = 0.4;
		strumUnderlay.scrollFactor.set();
		if(FlxG.save.data.laneUnderlay)
			add(strumUnderlay);

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		if (FlxG.save.data.downScroll)
			strumLine.y = FlxG.height - 130;
		strumLine.scrollFactor.set();

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		cpuStrums = new FlxTypedGroup<FlxSprite>();
		add(cpuStrums);

		add(noteSplashes);

		playerStrums = new FlxTypedGroup<FlxSprite>();

		// startCountdown();

		generateSong(SONG.song);

		if (isMod && FileSystem.exists("mods/data/" + SONG.song.toLowerCase() + "/events.txt")){
			var daList:Array<String> = File.getContent("mods/data/" + SONG.song.toLowerCase() + "/events.txt").trim().split('\n');
	
			for (i in 0...daList.length)
			{
				daList[i] = daList[i].trim();
			}

			events = daList;
			trace(events);
		}
		else if (FileSystem.exists(Paths.file("data/" + SONG.song.toLowerCase() + "/events.txt")))
			events = CoolUtil.coolTextFile(Paths.file('data/' + SONG.song.toLowerCase() + '/events.txt'));

		if (songScrollSpeed != PlayState.SONG.speed)
			songScrollSpeed = PlayState.SONG.speed;

		// add(strumLine);

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		if (!FlxG.save.data.liteMode)
			FlxG.camera.follow(camFollow, LOCKON, 0.04);

		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, (FlxG.save.data.downScroll == false) ? FlxG.height * 0.9 : 50).loadGraphic(Paths.image('healthBar'));
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		// healthBar
		add(healthBar);

		var barColor:FlxColor = 0xFF000000;
		var barColor2:FlxColor = 0xFF000000;

		for (color in CoolUtil.coolTextFile(Paths.txt('healthcolors'))) {
			if (!color.startsWith('#')) {
				var eugh = color.split(':');

				if (dad.curCharacter.toLowerCase().startsWith(eugh[0])) {
					barColor = new FlxColor(Std.parseInt(eugh[1]));
				}
				if (boyfriend.curCharacter.toLowerCase().startsWith(eugh[0])) {
					barColor2 = new FlxColor(Std.parseInt(eugh[1]));
				}
			}
		}

		if (!FlxG.save.data.disablehealthColor){
			healthBar.createFilledBar(barColor, barColor2);
		}

		songBarBG = new FlxSprite(0, (FlxG.save.data.downScroll == false) ? FlxG.height * 0.85 : 150).makeGraphic(Std.int(healthBarBG.width), Std.int(healthBarBG.height), 0xFF000000);
		songBarBG.setGraphicSize(Std.int(songBarBG.width * 0.5), Std.int(songBarBG.height * 1.5));
		songBarBG.updateHitbox();
		songBarBG.screenCenter(X);
		songBarBG.scrollFactor.set();
		add(songBarBG);
		
		songBar = new FlxBar(songBarBG.x + 4, songBarBG.y + 4, LEFT_TO_RIGHT, Std.int(songBarBG.width - 8), Std.int(songBarBG.height - 8), this,
		'songTime', 0, songLength);
		songBar.scrollFactor.set();
		songBar.createFilledBar(FlxColor.fromRGB(0, 51, 0), FlxColor.fromRGB(0, 153, 51));
		add(songBar);

		iconP1 = new HealthIcon(SONG.player1, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.setGraphicSize(20);
		iconP1.updateHitbox();
		add(iconP1);

		iconP2 = new HealthIcon(SONG.player2, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.setGraphicSize(20);
		iconP2.updateHitbox();
		add(iconP2);

		scoreTxt = new FlxText(0, healthBarBG.y + 46, FlxG.width, "", 24);
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, CENTER);
		scoreTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, 0xFF000000, 2, 1);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		noteSplashes.cameras = [camHUD];
		cpuStrums.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		strumUnderlay.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		songBar.cameras = [camHUD];
		songBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		doof.cameras = [camHUD];

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		if (isStoryMode)
		{
			switch (curSong.toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'tutorial':
					loadDialogue(doof);
				case 'senpai':
					loadDialogue(doof);
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					loadDialogue(doof);
				case 'thorns':
					loadDialogue(doof);
				// If you want to play a cutscene just add a new case for your song and add playCutscene()
				case 'ugh':
					playCutscene("ughCutscene");
				case 'guns':
					playCutscene("gunsCutscene");
				case 'stress':
					playCutscene("stressCutscene");

				default:
					startCountdown();
			}
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		}

		super.create();
	}

	function loadDialogue(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy', 'week6');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.song.toLowerCase() == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	function startCountdown():Void
	{
		inCutscene = false;

		generateStaticArrows(0);
		generateStaticArrows(1);

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dad.dance();
			gf.dance();
			boyfriend.playAnim('idle');

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			var introLibrary:String = '';
			var altSuffix:String = "";

			//more NoteSkin bullshit
			switch(SONG.noteskin){
				case 'pixel':
					introAssets.set('default', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);
					introLibrary = 'week6';
					altSuffix = '-pixel';
				default:
					introAssets.set('default', ['ready', "set", "go"]);
					introLibrary = 'shared';
					altSuffix = '';
			}

			var introAlts:Array<String> = introAssets.get('default');

			for (value in introAssets.keys())
			{
				if (value == curStage)
				{
					introAlts = introAssets.get(value);
				}
			}

			switch (swagCounter)

			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0], introLibrary));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (introLibrary == 'week6')
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1], introLibrary));
					set.scrollFactor.set();

					if (introLibrary == 'week6')
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2], introLibrary));
					go.scrollFactor.set();

					if (introLibrary == 'week6')
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
				case 4:
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused && !isMod)
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		else if (!paused && isMod)
			FlxG.sound.playMusic(Sound.fromFile("mods/songs/" + PlayState.SONG.song.toLowerCase() + "/Inst.ogg"), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		songBar.setRange(songTime, songLength);

		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end
	}

	var debugNum:Int = 0;

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices && inCutscene == false && !isMod)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
		else if (SONG.needsVoices && inCutscene == false && isMod)
			vocals = new FlxSound().loadEmbedded(Sound.fromFile("mods/songs/" + PlayState.SONG.song.toLowerCase() + "/Voices.ogg"));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else {}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var babyArrow:FlxSprite = new FlxSprite(0, strumLine.y);

			//NoteSkin (Regular Notes - For Sustain, Open Note.hx)
			switch (SONG.noteskin)
			{
				 default:
					babyArrow.frames = Paths.getSparrowAtlas('NOTE_assets');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					}
				
				case 'circle':
					babyArrow.frames = Paths.getSparrowAtlas('NOTE_CIRCLE_assets');
					babyArrow.animation.addByPrefix('green', 'arrowUP');
					babyArrow.animation.addByPrefix('blue', 'arrowDOWN');
					babyArrow.animation.addByPrefix('purple', 'arrowLEFT');
					babyArrow.animation.addByPrefix('red', 'arrowRIGHT');

					babyArrow.antialiasing = true;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.addByPrefix('static', 'arrowLEFT');
							babyArrow.animation.addByPrefix('pressed', 'left press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'left confirm', 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.addByPrefix('static', 'arrowDOWN');
							babyArrow.animation.addByPrefix('pressed', 'down press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'down confirm', 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.addByPrefix('static', 'arrowUP');
							babyArrow.animation.addByPrefix('pressed', 'up press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'up confirm', 24, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.addByPrefix('static', 'arrowRIGHT');
							babyArrow.animation.addByPrefix('pressed', 'right press', 24, false);
							babyArrow.animation.addByPrefix('confirm', 'right confirm', 24, false);
					}

				case 'pixel':
					babyArrow.loadGraphic(Paths.image('weeb/pixelUI/arrows-pixels', 'week6'), true, 17, 17);
					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purplel', [4]);

					babyArrow.setGraphicSize(Std.int(babyArrow.width * daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;
	
					strumUnderlay.setPosition(686, 0);

					switch (Math.abs(i))
					{
						case 0:
							babyArrow.x += Note.swagWidth * 0;
							babyArrow.animation.add('static', [0]);
							babyArrow.animation.add('pressed', [4, 8], 12, false);
							babyArrow.animation.add('confirm', [12, 16], 24, false);
						case 1:
							babyArrow.x += Note.swagWidth * 1;
							babyArrow.animation.add('static', [1]);
							babyArrow.animation.add('pressed', [5, 9], 12, false);
							babyArrow.animation.add('confirm', [13, 17], 24, false);
						case 2:
							babyArrow.x += Note.swagWidth * 2;
							babyArrow.animation.add('static', [2]);
							babyArrow.animation.add('pressed', [6, 10], 12, false);
							babyArrow.animation.add('confirm', [14, 18], 12, false);
						case 3:
							babyArrow.x += Note.swagWidth * 3;
							babyArrow.animation.add('static', [3]);
							babyArrow.animation.add('pressed', [7, 11], 12, false);
							babyArrow.animation.add('confirm', [15, 19], 24, false);
					}
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (!isStoryMode)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}

			babyArrow.ID = i;

			switch (player)
			{
				case 0:
					cpuStrums.add(babyArrow);
				case 1:
					playerStrums.add(babyArrow);
			}

			babyArrow.animation.play('static');
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * player);

			cpuStrums.forEach(function(spr:FlxSprite)
				{
					spr.centerOffsets();
				});

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			paused = false;

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength - Conductor.songPosition);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float)
	{
		#if !debug
		perfectMode = false;
		#end

		if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}

		switch (curStage)
		{
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		super.update(elapsed);

		scoreTxt.text = 'Score: $songScore | Misses: $misses | S/G/B/S: $sicks/$goods/$bads/$shits | Combo: $combo | ${calculateRating()}';

		if (FlxG.keys.justPressed.ENTER && startedCountdown && canPause)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000 chance for Gitaroo Man easter egg
			if (FlxG.random.bool(0.1))
			{
				// gitaroo man easter egg
				FlxG.switchState(new GitarooPause());
			}
			else
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		
			#if desktop
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new ChartingState());

			#if desktop
			DiscordClient.changePresence("Chart Editor", null, null, true);
			#end
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width - 50, 0.50)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width - 50, 0.50)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP2.y = healthBar.y - (iconP2.height / 2);

		var iconOffset:Int = 20;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (iconP1.overlaps(songBar)){
			iconP1.alpha = 0.65;
		}
		else{
			iconP1.alpha = 1;
		}

		if (iconP2.overlaps(songBar)){
			iconP2.alpha = 0.65;
		}
		else{
			iconP2.alpha = 1;
		}

		// Panic the BF
		if (!FlxG.save.data.disablePanicableBF && !FlxG.save.data.liteMode){
			if (ogBF == 'bf' || ogBF == 'bf-christmas'){
				if(health >= 0.715 && !inPanic){
					remove(boyfriend);
					boyfriend = new Boyfriend(boyfriend.x, boyfriend.y, ogBF);
					add(boyfriend);
	
					inPanic = true;
				}
				
				if (health <= 0.715 && inPanic){
					remove(boyfriend);
					boyfriend = new Boyfriend(boyfriend.x, boyfriend.y, ogBF + 'panic');
					add(boyfriend);
	
					inPanic = false;
				}
	
				//trace(inPanic + " lmao");
			}
		}

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		#if debug
		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new AnimationDebug(SONG.player2));
		#end

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (curBeat % 4 == 0)
			{
				// trace(PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection);
			}

			if (camFollow.x != dad.getMidpoint().x + 150 && !PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection)
			{
				camFollow.setPosition(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
				// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

				switch (dad.curCharacter)
				{
					case 'mom':
						camFollow.y = dad.getMidpoint().y;
					case 'senpai':
						camFollow.y = dad.getMidpoint().y - 430;
						camFollow.x = dad.getMidpoint().x - 100;
					case 'senpai-angry':
						camFollow.y = dad.getMidpoint().y - 430;
						camFollow.x = dad.getMidpoint().x - 100;
				}

				if (dad.curCharacter == 'mom')
					vocals.volume = 1;

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					tweenCamIn();
				}
			}

			if (PlayState.SONG.notes[Std.int(curStep / 16)].mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				camFollow.setPosition(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

				switch (curStage)
				{
					case 'limo':
						camFollow.x = boyfriend.getMidpoint().x - 300;
					case 'mall':
						camFollow.y = boyfriend.getMidpoint().y - 200;
					case 'school':
						camFollow.x = boyfriend.getMidpoint().x - 200;
						camFollow.y = boyfriend.getMidpoint().y - 200;
					case 'schoolEvil':
						camFollow.x = boyfriend.getMidpoint().x - 200;
						camFollow.y = boyfriend.getMidpoint().y - 200;
				}

				if (SONG.song.toLowerCase() == 'tutorial')
				{
					FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
				}
			}
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}

		// CHEAT = brandon's a pussy
		if (controls.CHEAT)
		{
			#if !DEBUG
			trace('player is NOT allowed to cheat, he is a pussy');
			health -= 99;
			#else
			trace('player is allowed to cheat, he is still a pussy');
			health += 1;
			#end
		}

		if (health <= 0)
		{
			boyfriend.stunned = true;

			persistentUpdate = false;
			persistentDraw = false;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();

			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

			// FlxG.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			
			#if desktop
			// Game Over doesn't get his own variable because it's only used here
			DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
			#end
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				if (!FlxG.save.data.downScroll)
					daNote.y = (strumLine.y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(songScrollSpeed, 2)));
				else
					daNote.y = (strumLine.y + (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(songScrollSpeed, 2)));

				// i am so fucking sorry for this if condition
				if (FlxG.save.data.downScroll == false ? daNote.isSustainNote
					&& daNote.y + daNote.offset.y <= strumLine.y + Note.swagWidth / 2
					&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))) : daNote.isSustainNote
					&& daNote.y + daNote.offset.y >= strumLine.y + Note.swagWidth / 2
					&& (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					var swagRect = new FlxRect(0, strumLine.y + Note.swagWidth / 2 - daNote.y, daNote.width * 2, daNote.height * 2);
					swagRect.y /= daNote.scale.y;
					swagRect.height -= swagRect.y;

					daNote.clipRect = swagRect;
				}

				if ((FlxG.save.data.downScroll == false) ? daNote.mustPress && daNote.y <= strumLine.y && FlxG.save.data.botplay :
					daNote.mustPress && daNote.y >= strumLine.y && FlxG.save.data.botplay)
				{
					switch (Math.abs(daNote.noteData))
					{
						case 0:
							boyfriend.playAnim('singLEFT', true);
						case 1:
							boyfriend.playAnim('singDOWN', true);
						case 2:
							boyfriend.playAnim('singUP', true);
						case 3:
							boyfriend.playAnim('singRIGHT', true);
					}

					playerStrums.forEach(function(spr:FlxSprite)
						{
							if (Math.abs(daNote.noteData) == spr.ID)
							{	
								spr.animation.play('confirm', true);
								
								if (!daNote.isSustainNote)
									noteSplash(daNote.x, daNote.y, daNote.noteData, false);
							}

							// CPU PlayerStrum NoteSkin Confirm Offsets
							if (spr.animation.curAnim.name == 'confirm')
								{
									switch (SONG.noteskin){
										default:
											spr.centerOffsets();
											spr.offset.x -= 13;
											spr.offset.y -= 13;
										case 'pixel':
											// not needed
										case 'circle':
											spr.centerOffsets();
									}
								}
								else{
									spr.centerOffsets();
								}
						});
					
					if (!daNote.isSustainNote){
						combo++;
						sicks++;
						health += 0.1;
					}
					
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				if (!daNote.mustPress && daNote.wasGoodHit)
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					var altAnim:String = "";

					if (SONG.notes[Math.floor(curStep / 16)] != null)
					{
						if (SONG.notes[Math.floor(curStep / 16)].altAnim)
							altAnim = '-alt';
					}

					switch (Math.abs(daNote.noteData))
					{
						case 0:
							dad.playAnim('singLEFT' + altAnim, true);
						case 1:
							dad.playAnim('singDOWN' + altAnim, true);
						case 2:
							dad.playAnim('singUP' + altAnim, true);
						case 3:
							dad.playAnim('singRIGHT' + altAnim, true);
					}

					// Custom Singing Animations
					switch (SONG.song.toLowerCase()){
						case 'ugh':
							switch (curStep)
							{
								case 60:
									dad.playAnim('ugh', true);
								case 444:
									dad.playAnim('ugh', true);
								case 524:
									dad.playAnim('ugh', true);
								case 828:
									dad.playAnim('ugh', true);
							}
						case 'ugh-swagmix':
							switch (curStep)
							{
								case 60:
									dad.playAnim('ugh', true);
								case 62:
									dad.playAnim('ugh', true);
								case 63:
									dad.playAnim('ugh', true);
								case 444:
									dad.playAnim('ugh', true);
								case 446:
									dad.playAnim('ugh', true);
								case 447:
									dad.playAnim('ugh', true);
								case 524:
									dad.playAnim('ugh', true);
								case 525:
									dad.playAnim('ugh', true);
								case 540:
									dad.playAnim('ugh', true);
								case 542:
									dad.playAnim('ugh', true);
								case 828:
									dad.playAnim('ugh', true);
								case 830:
									dad.playAnim('ugh', true);
								case 831:
									dad.playAnim('ugh', true);
							}
					}

					dad.holdTimer = 0;

					if (SONG.needsVoices)
						vocals.volume = 1;

					//CPUSTRUM CONFIRM ANIMATION
					cpuStrums.forEach(function(spr:FlxSprite)
						{
							if (Math.abs(daNote.noteData) == spr.ID)
							{	
								spr.animation.play('confirm', true);
								
								if (!daNote.isSustainNote)
									noteSplash(daNote.x, daNote.y, daNote.noteData, true);										
							}

							//CPUSTRUM NoteSkin Confirm Offsets
							if (spr.animation.curAnim.name == 'confirm')
							{
								switch (SONG.noteskin){
									default:
										spr.centerOffsets();
										spr.offset.x -= 13;
										spr.offset.y -= 13;
									case 'pixel':
										// not needed
									case 'circle':
										spr.centerOffsets();
								}
							}
							else{
								spr.centerOffsets();
							}
						});


					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * songScrollSpeed));

				//-strumLine.y - 16

				//DaNote was too late
				if ((FlxG.save.data.downScroll == false) ? daNote.y < -daNote.height && !FlxG.save.data.botplay : daNote.y > FlxG.height + daNote.height && !FlxG.save.data.botplay)
				{
					//fnf is weird
					if (daNote.tooLate && !daNote.wasGoodHit || !daNote.wasGoodHit)
					{
						trace("Missed! Note was too late");
						misses++;
						songScore -= 10;
						combo = 0;
						FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
						health -= 0.0475;
						vocals.volume = 0;

						daNote.active = false;
						daNote.visible = false;

						//Miss Animation
						switch (Math.abs(daNote.noteData)){
							case 0:
								boyfriend.playAnim('singLEFTmiss', true);
							case 1:
								boyfriend.playAnim('singDOWNmiss', true);
							case 2:
								boyfriend.playAnim('singUPmiss', true);
							case 3:
								boyfriend.playAnim('singRIGHTmiss', true);
							default:
								boyfriend.playAnim('singLEFTmiss', true); // just in case lmao
						}
						
	
						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				}
			});
		}

		cpuStrums.forEach(function(spr:FlxSprite)
			{
				if (spr.animation.finished && spr.animation.curAnim.name == 'confirm')
				{
					spr.animation.play('static');
					spr.centerOffsets();
					// trace('confirm animation finished');
				}
			});
		
		if (FlxG.save.data.botplay){
			playerStrums.forEach(function(spr:FlxSprite)
				{
					if (spr.animation.finished && spr.animation.curAnim.name == 'confirm')
					{
						spr.animation.play('static');
						spr.centerOffsets();
					}
				});
			
			if (boyfriend.animation.finished && boyfriend.animation.curAnim.name != 'idle'){
				boyfriend.playAnim('idle', true);
			}
		}

		if (!inCutscene && !FlxG.save.data.botplay)
			keyShit();

		#if debug
		if (FlxG.keys.justPressed.ONE){
			endSong();
			trace('fucking cheating ass bitch');
		}
		#end
	}

	function endSong():Void
	{
		// Play EndCutscene
		if (playedEndCutscene == false && isStoryMode == true){
			switch (curSong.toLowerCase())
			{
				case 'pico':
					if (FlxG.random.bool(25))
						playEndCutscene("cock");
				case 'stress':
					playEndCutscene("kickstarterTrailer");
			}
		}

		if (inCutscene == false){
			canPause = false;
			secretMode = false;
			FlxG.sound.music.volume = 0;
			vocals.volume = 0;
			if (SONG.validScore)
			{
				#if !switch
				Highscore.saveScore(SONG.song, songScore, storyDifficulty);
				#end
			}

			isMod = false;

			camHUD.fade(FlxColor.TRANSPARENT, 0.5, false, null, true);

			if (isStoryMode)
			{
				campaignScore += songScore;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;

					FlxG.switchState(new StoryMenuState());

					// if ()
					StoryMenuState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryMenuState.weekUnlocked.length - 1))] = true;

					if (SONG.validScore)
					{
						Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
					}

					FlxG.save.data.weekUnlocked = StoryMenuState.weekUnlocked;
					FlxG.save.flush();
				}
				else
				{
					var difficulty:String = "";

					if (storyDifficulty == 0)
						difficulty = '-easy';

					if (storyDifficulty == 2)
						difficulty = '-hard';

					trace('LOADING NEXT SONG');
					trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);	

					if (SONG.song.toLowerCase() == 'eggnog')
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;
					prevCamFollow = camFollow;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY?? ' + isMod);
				FlxG.switchState(new FreeplayState());
			}
		}
	}

	var endingSong:Bool = false;

	private function popUpScore(strumtime:Float, daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(strumtime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		var daRating:String = "sick";

		if (FlxG.save.data.judgeHits){
			if (noteDiff > Conductor.safeZoneOffset * 0.9)
				{
					shits++;
					daRating = 'shit';
					score = 50;
				}
				else if (noteDiff > Conductor.safeZoneOffset * 0.75)
				{
					bads++;
					daRating = 'bad';
					score = 100;
				}
				else if (noteDiff > Conductor.safeZoneOffset * 0.2)
				{
					goods++;
					daRating = 'good';
					score = 200;
				}
				else {
					sicks++;
				}
		}
		else{
			if (noteDiff > Conductor.safeZoneOffset * 0.75)
				{
					shits++;
					daRating = 'shit';
					health -= 0.04;
					score = 50;
				}
				else if (noteDiff > Conductor.safeZoneOffset * 0.38)
				{
					bads++;
					daRating = 'bad';
					score = 100;
				}
				else if (noteDiff > Conductor.safeZoneOffset * 0.175) //this game is making me lose my sanity
				{
					goods++;
					daRating = 'good';
					score = 200;
				}
				else {
					sicks++;
				}
		}

		daNote.daRating = daRating;
		songScore += score;

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';
		var pixelShitLibrary:String = 'shared';

		// NoteSkin (pixelShit) it is multiple string's that is used to determine the asset path of the note skin.
		switch(SONG.noteskin){
			default:
				//not needed
			case 'pixel':
				pixelShitPart1 = 'weeb/pixelUI/';
				pixelShitPart2 = '-pixel';
				pixelShitLibrary = 'week6';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2, pixelShitLibrary));
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2, pixelShitLibrary));
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		add(rating);

		// Increase Graphic Size for NoteSkin (pixelShit)
		switch(SONG.noteskin){
			default:
				rating.setGraphicSize(Std.int(rating.width * 0.7));
				rating.antialiasing = true;
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
				comboSpr.antialiasing = true;
			case 'pixel':
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));

		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		for (_i in Std.string(combo).split("")) {
			seperatedScore.push(Std.parseInt(_i));
		}

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2, pixelShitLibrary));
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			switch(SONG.noteskin){
				default:
					numScore.antialiasing = true;
					numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				case 'pixel':
					numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
	
			}

			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	private function keyShit():Void
		{
			var up = controls.UP;
			var right = controls.RIGHT;
			var down = controls.DOWN;
			var left = controls.LEFT;
	
			var upP = controls.UP_P;
			var rightP = controls.RIGHT_P;
			var downP = controls.DOWN_P;
			var leftP = controls.LEFT_P;
	
			var upR = controls.UP_R;
			var rightR = controls.RIGHT_R;
			var downR = controls.DOWN_R;
			var leftR = controls.LEFT_R;
	
			var controlArray:Array<Bool> = [leftP, downP, upP, rightP];
	
			if ((upP || rightP || downP || leftP) && !boyfriend.stunned && generatedMusic)
			{
				boyfriend.holdTimer = 0;
	
				var possibleNotes:Array<Note> = [];
	
				var ignoreList:Array<Int> = [];
	
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
					{
						possibleNotes.push(daNote);
						possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
	
						ignoreList.push(daNote.noteData);
					}
				});
	
				if (possibleNotes.length > 0)
				{
					var daNote = possibleNotes[0];
	
					if (perfectMode)
						noteCheck(true, daNote);
	
					// Jump notes
					if (possibleNotes.length >= 2)
					{
						if (possibleNotes[0].strumTime == possibleNotes[1].strumTime)
						{
							for (coolNote in possibleNotes)
							{
								if (controlArray[coolNote.noteData])
									goodNoteHit(coolNote);
							}
						}
						else if (possibleNotes[0].noteData == possibleNotes[1].noteData)
						{
							if (left || up || down || right) {
								noteCheck(controlArray[daNote.noteData], daNote);
							}
						}
						else
						{
							for (coolNote in possibleNotes)
							{
								if (left || up || down || right) {
									noteCheck(controlArray[coolNote.noteData], coolNote);
								}
							}
						}
					}
					else // regular notes?
					{
						if (left || up || down || right) {
							noteCheck(controlArray[daNote.noteData], daNote);
						}
					}
				}
				else
				{
					badNoteCheck();
				}
			}
	
			if ((up || right || down || left) && !boyfriend.stunned && generatedMusic)
			{
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && daNote.isSustainNote)
					{
						switch (daNote.noteData)
						{
							// NOTES YOU ARE HOLDING
							case 0:
								if ((left))
									goodNoteHit(daNote);
							case 1:
								if ((down))
									goodNoteHit(daNote);
							case 2:
								if ((up))
									goodNoteHit(daNote);
							case 3:
								if ((right))
									goodNoteHit(daNote);
						}
					}
				});
			}
	
			if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !up && !down && !right && !left)
			{
				if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
				{
					boyfriend.playAnim('idle');
				}
			}
	
			playerStrums.forEach(function(spr:FlxSprite)
			{
				switch (spr.ID)
				{
					case 0:
						if ((leftP) && spr.animation.curAnim.name != 'confirm')
							spr.animation.play('pressed');
						if (leftR)
							spr.animation.play('static');
					case 1:
						if ((downP) && spr.animation.curAnim.name != 'confirm')
							spr.animation.play('pressed');
						if (downR)
							spr.animation.play('static');
					case 2:
						if ((upP) && spr.animation.curAnim.name != 'confirm')
							spr.animation.play('pressed');
						if (upR)
							spr.animation.play('static');
					case 3:
						if ((rightP) && spr.animation.curAnim.name != 'confirm')
							spr.animation.play('pressed');
						if (rightR)
							spr.animation.play('static');
				}
	
				try {
					if (spr.animation.curAnim.name == 'confirm')
						{
							// Player NoteSkin Confirm Offsets
							switch (SONG.noteskin){
								default:
									spr.centerOffsets();
									spr.offset.x -= 13;
									spr.offset.y -= 13;
								case 'pixel':
									// not needed
								case 'circle':
									spr.centerOffsets();
							}
						}
						else{
							spr.centerOffsets();
						}
					
				} catch (e) {
					trace('FUCK! ${e.details}');
				}
			});
		}

		function noteMiss(direction:Int = 1):Void
			{
				if (!boyfriend.stunned)
				{
					if (!FlxG.save.data.gtapping) {
						misses++;
						if (true)
							health -= 0.04;
						else
							health = 0;
		
						if (combo > 5 && gf.animOffsets.exists('sad'))
						{
							gf.playAnim('sad');
						}
						combo = 0;
		
						songScore -= 10;
		
						FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
						// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
						// FlxG.log.add('played imss note');

						boyfriend.stunned = true;
		
						// get stunned for 5 seconds
						new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
						{
							boyfriend.stunned = false;
						});
					}

					if (!FlxG.save.data.gtapping){
						switch (direction)
						{
							case 0:
								boyfriend.playAnim('singLEFTmiss', true);
							case 1:
								boyfriend.playAnim('singDOWNmiss', true);
							case 2:
								boyfriend.playAnim('singUPmiss', true);
							case 3:
								boyfriend.playAnim('singRIGHTmiss', true);
						}
					}
				}
			}

			function badNoteCheck()
				{
					// just double pasting this shit cuz fuk u
					// REDO THIS SYSTEM!
					var upP = controls.UP_P;
					var rightP = controls.RIGHT_P;
					var downP = controls.DOWN_P;
					var leftP = controls.LEFT_P;
			
					if (leftP ) {
						noteMiss(0);
						//trace("gtap L");
					}
					if (downP) {
						noteMiss(1);
						//trace("gtap D");
					}
					if (upP) {
						noteMiss(2);
						//trace("gtap U");
					}
					if (rightP) {
						noteMiss(3);
						//trace("gtap R");
			
					}
					
				}

	function noteCheck(keyP:Bool, note:Note):Void
	{
		if (keyP)
			goodNoteHit(note);
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (!note.isSustainNote)
			{
				popUpScore(note.strumTime, note);
				combo += 1;
			}

			if (note.noteData >= 0)
				health += 0.023;
			else
				health += 0.004;

			switch (note.noteData)
			{
				case 0:
					boyfriend.playAnim('singLEFT', true);
				case 1:
					boyfriend.playAnim('singDOWN', true);
				case 2:
					boyfriend.playAnim('singUP', true);
				case 3:
					boyfriend.playAnim('singRIGHT', true);
			}

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
				}
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (note.wasGoodHit && note.daRating == 'sick')
				noteSplash(note.x, note.y, note.noteData, false);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		halloweenBG.animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			resyncVocals();
		}

		if (dad.curCharacter == 'spooky' && curStep % 4 == 2)
		{
			// dad.dance();
		}

		//events lol
		for (event in events){
			var tempStep = event.split(":");

			//trace(event);
			//trace(tempStep[0] + " " + tempStep[1]);

			//curStep in 0, event in 1
			if (Std.parseInt(tempStep[0]) == curStep){
				switch(tempStep[1].toLowerCase()){
					case 'setsongspeed':
						songScrollSpeed = Std.parseFloat(tempStep[2]);
						trace("SET SPEED TO " + songScrollSpeed);
					case 'gfcheer':
						gf.playAnim('cheer', true);
						trace("GF CHEER");
					case 'playanimation.dad':
						dad.playAnim(tempStep[2], true);
						trace("DAD ANIM " + tempStep[2]);
					case 'playanimation.boyfriend':
						boyfriend.playAnim(tempStep[2], true);
						trace("BOYFRIEND ANIM " + tempStep[2]);
					case 'playanimation.girlfriend':
						gf.playAnim(tempStep[2], true);
						trace("GIRLFRIEND ANIM " + tempStep[2]);
				}
			}
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
				dad.dance();
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		wiggleShit.update(Conductor.crochet);

		// HARDCODING FOR MILF ZOOMS!
		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (curSong.toLowerCase() == 'guns' && secretMode){
			// i don't really care if this is coded properly cuz its just a dumb lil easteregg
			if (curBeat >= 224 && curBeat < 256)
				dad.y -= 25;
			if (curBeat >= 256 && curBeat < 288)
				boyfriend.y -= 25;
			if (curBeat >= 288 && curBeat < 320)
				dad.y -= 25;
			if (curBeat >= 320 && curBeat < 353)
				boyfriend.y -= 25;
			if (curBeat >= 353 && curBeat < 385){
				boyfriend.y += 55;
				dad.y += 55;
			}

			//Cam Y
			if (curBeat >= 224 && curBeat < 353)
				camFollow.y -= 25;
			if (curBeat >= 353 && curBeat < 385)
				camFollow.y += 55;
		}

		if (curSong.toLowerCase() == 'stress') 
			{
				switch (curBeat)
				{
					case 184:
						dad.playAnim('prettygood', true);
				 }
			}

		if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (curBeat % gfSpeed == 0)
		{
			gf.dance();
		}

		if (boyfriend.animation.curAnim.name.startsWith("idle"))
		{
			boyfriend.playAnim('idle');
		}

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
		{
			boyfriend.playAnim('hey', true);
		}

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
		{
			boyfriend.playAnim('hey', true);
			dad.playAnim('cheer', true);
		}

		switch (curStage)
		{
			case 'school':
				bgGirls.dance();

			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'limo':
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
					dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					if (!FlxG.save.data.epilepsyMode){
						phillyCityLights.forEach(function(light:FlxSprite)
							{
								light.visible = false;
							});
		
							curLight = FlxG.random.int(0, phillyCityLights.length - 1);
		
							phillyCityLights.members[curLight].visible = true;
							// phillyCityLights.members[curLight].alpha = 1;
					}
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8 && !FlxG.save.data.noDistractions)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset && !FlxG.save.data.noDistractions)
		{
			lightningStrikeShit();
		}
	}

	public function calculateRating() {
		if (misses == 0) {
			if (goods < 1 && bads < 1 && shits < 1){
				return 'PERFECT! (MFC) (${calculateLetter()} | ${calcAcc()})';
			}
			else{
				return 'SICK! (FC) (${calculateLetter()} | ${calcAcc()})';
			}
		}
		else if (misses > 0 && misses <= 10) {
			return 'GOOD! (SDM) (${calculateLetter()} | ${calcAcc()})';
		}
		else {
			return 'BAD (Clear) (${calculateLetter()} | ${calcAcc()})';
		}
	}

	function calculateLetter() {
		if (sicks > 0 || goods > 0 || bads > 0 || shits > 0 || misses > 0)
			return '${sicks > goods ? 'A' : ''}${sicks > bads ? 'A' : ''}${sicks > shits ? 'A': ''}${sicks > misses ? 'A' : ''}';
		else
			return '?';
	}

	function calcAcc() {
		if (sicks > 0 || goods > 0 || bads > 0 || shits > 0 || misses > 0)
			return '${Math.floor((((sicks + goods + bads + shits) / 100) / ((misses + sicks + goods + bads + shits) / 100)) * 100)}%';
		else
			return '?';
	}

	function playCutscene(name:String)
	{
		#if (windows || linux)
		inCutscene = true;

		var video:VideoHandler = new VideoHandler();
		video.finishCallback = function()
		{
			startCountdown();
		}
		video.playVideo(Paths.video(name));
		#else
		startCountdown();
		#end
	}
	
	function playEndCutscene(name:String)
	{
		//Doesn't check if the song is ending sense it gets called to play WHILE the song is ending.
		inCutscene = true;

		//KILL THE MUSIC!!!
		FlxG.sound.music.kill();
		vocals.kill();

		#if (windows || linux)
		inCutscene = true;

		var video:VideoHandler = new VideoHandler();
		video.finishCallback = function()
		{
			inCutscene = false;
			playedEndCutscene = true;
			endSong();
		}
		video.playVideo(Paths.video(name));
		#else
		inCutscene = false;
		playedEndCutscene = true;
		endSong();
		#end
	}

	function noteSplash(noteX:Float, noteY:Float, nData:Int, ?isDad = false)
		{
			var recycledNote = noteSplashes.recycle(NoteSplash);
			if (!isDad)    
				recycledNote.makeSplash(playerStrums.members[nData].x, playerStrums.members[nData].y, nData);
			else
				recycledNote.makeSplash(cpuStrums.members[nData].x, cpuStrums.members[nData].y, nData);
			noteSplashes.add(recycledNote);
		}

	var curLight:Int = 0;

	var songBarBG:FlxSprite;
	var songBar:FlxBar;
}
