package kha.js;

import js.Browser;
import js.html.ErrorEvent;
import js.html.Event;
import js.html.MediaError;
import js.html.VideoElement;
import js.html.MediaStreamEvent;

using StringTools;

class Video extends kha.Video {
	public var element: VideoElement;
	public var texture: Image;

	var filenames: Array<String>;
	var done: kha.Video->Void;

	function new() {
		super();
	}

	public static function fromElement(element: js.html.VideoElement): Video {
		var video = new Video();
		video.element = element;
		if (SystemImpl.gl != null)
			video.texture = Image.fromVideo(video);
		return video;
	}

	public static function fromFile(filenames: Array<String>, done: kha.Video->Void): Void {
		var video = new Video();

		video.done = done;

		video.element = cast Browser.document.createElement("video");

		video.filenames = [];
		for (filename in filenames) {
			if (video.element.canPlayType("video/webm") != "" && filename.endsWith(".webm"))
				video.filenames.push(filename);
			#if !kha_krom
			if (video.element.canPlayType("video/mp4") != "" && filename.endsWith(".mp4"))
				video.filenames.push(filename);
			#end
		}

		video.element.addEventListener("error", video.errorListener, false);
		video.element.addEventListener("canplaythrough", video.canPlayThroughListener, false);
		// video.element.addEventListener("abort", something, false);
		// video.element.addEventListener("canplay", something, false);
		// video.element.addEventListener("durationchange", something, false);
		// video.element.addEventListener("emptied", something, false);
		// video.element.addEventListener("encrypted", something, false);
		// video.element.addEventListener("ended", something, false);
		// video.element.addEventListener("interruptbegin", something, false);
		// video.element.addEventListener("interruptend", something, false);
		// video.element.addEventListener("loadeddata", something, false);
		// video.element.addEventListener("loadstart", something, false);
		// video.element.addEventListener("mozaudioavailable", something, false);
		// video.element.addEventListener("pause", something, false);
		// video.element.addEventListener("play", something, false);
		// video.element.addEventListener("playing", something, false);
		// video.element.addEventListener("progress", something, false);
		// video.element.addEventListener("ratechange", something, false);
		// video.element.addEventListener("seeked", something, false);
		// video.element.addEventListener("seeking", something, false);
		// video.element.addEventListener("stalled", something, false);
		// video.element.addEventListener("suspend", something, false);
		// video.element.addEventListener("timeupdate", something, false);
		// video.element.addEventListener("volumechange", something, false);
		// video.element.addEventListener("waiting", something, false);
		video.element.addEventListener("loadedmetadata", onMetaDataLoaded, false);		

		video.element.preload = "auto";
		video.element.crossOrigin = "anonymous"; //Enable cross-origin playback of video
		video.element.muted = true; //Enable auto-playback without user interact		
		video.element.src = video.filenames[0];
	}

	static public function onMetaDataLoaded(e:MediaStreamEvent)
	{
		var ve:VideoElement = cast e.target;
		ve.play(); //Sometimes autplay fails; this should enforce it....
	}

	override public function width(): Int {
		return element.videoWidth;
	}

	override public function height(): Int {
		return element.videoHeight;
	}

	override public function play(loop: Bool = false): Void {
		try {
			element.loop = loop;
			element.play();
		}
		catch (e:Dynamic) {
			trace(e);
		}
	}

	override public function pause(): Void {
		try {
			element.pause();
		}
		catch (e:Dynamic) {
			trace(e);
		}
	}

	override public function stop(): Void {
		try {
			element.pause();
			element.currentTime = 0;
		}
		catch (e:Dynamic) {
			trace(e);
		}
	}

	override public function getCurrentPos(): Int {
		return Math.ceil(element.currentTime * 1000); // Miliseconds
	}

	override function get_position(): Int {
		return Math.ceil(element.currentTime * 1000);
	}

	override function set_position(value: Int): Int {
		element.currentTime = value / 1000;
		return value;
	}

	override public function getVolume(): Float {
		return element.volume;
	}

	override public function setVolume(volume: Float): Void {
		if (element.muted && volume > 0)
			element.muted = false;
		element.volume = volume;
	}

	override public function getLength(): Int {
		if (Math.isFinite(element.duration)) {
			return Math.floor(element.duration * 1000); // Miliseconds
		}
		else {
			return -1;
		}
	}

	function errorListener(eventInfo: ErrorEvent): Void {
		if (element.error.code == MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED) {
			for (i in 0...filenames.length - 1) {
				if (element.src == filenames[i]) {
					// try loading with next extension:
					element.src = filenames[i + 1];
					return;
				}
			}
		}

		trace("Error loading " + element.src);
		finishAsset();
	}

	function canPlayThroughListener(eventInfo: Event): Void {
		finishAsset();
	}

	function finishAsset() {
		element.removeEventListener("error", errorListener, false);
		element.removeEventListener("canplaythrough", canPlayThroughListener, false);
		element.removeEventListener("loadedmetadata", onMetaDataLoaded, false);
		if (SystemImpl.gl != null)
			texture = Image.fromVideo(this);
		done(this);
	}
}
