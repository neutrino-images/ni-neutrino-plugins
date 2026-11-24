# Version 0.1.2; 24/11/2026
#
# WebTV-Livestream-Script fuer Neutrino (benoetigt Neutrino mit Python-
# Unterstuetzung, --enable-python).
#
# Neutrino uebergibt die Kanal-URL als sys.argv[1] und erwartet in der
# globalen Variable 'result' das Ergebnis als JSON-String, wie ihn ein
# Lua-Script zurueckgibt, z.B. '{"url": "..."}'. Ein dict oder eine Liste
# wird von Neutrino nicht gelesen. Bleibt 'result' leer, gilt der Aufruf
# als fehlgeschlagen.
#
# Streamlink wird direkt als Python-Modul benutzt. Ist das Modul nicht
# importierbar, wird wie bisher das streamlink-Kommando aufgerufen.
#
# Neutrino startet den Python-Interpreter nur einmal; jeder Aufruf dieses
# Scripts bekommt einen frischen Namespace, aber sys.modules bleibt. Die
# Streamlink-Session wird deshalb in einem eigenen Eintrag in sys.modules
# gehalten und bei jedem Umschalten wiederverwendet:
# - Streamlink() ist auf der Box teuer (rund 2 s), solange Streamlink seine
#   Plugins nicht lazy laden kann: per "setup.py install" installiert fehlt
#   die RECORD-Datei, gegen die es _plugins.json prueft, und dann fuehrt
#   jede neue Session alle Plugin-Module neu aus.
# - Ueber session.http laufen auch die stvp-Weiterleitungen, so bleiben die
#   Verbindungen zu jmp2.uk und Co. offen (keep-alive) und das naechste
#   Umschalten spart den TLS-Handshake.

import json
import ssl
import subprocess
import sys
import threading
import time
import types
import urllib.request
import warnings

# Reihenfolge der gewuenschten Qualitaeten, die erste vorhandene gewinnt
QUALITIES = ["1080p", "720p", "3300k", "2300k", "2100k", "best"]
TIMEOUT = 30

# Name des Eintrags in sys.modules, der die Session ueber Aufrufe haelt
CACHE_NAME = "_streamlink_loader_cache"

result = None


def log(msg):
	# Die Konsole der Box ist nicht unbedingt UTF-8: nie an einem Umlaut scheitern
	line = ("[streamlink-loader.py] %s\n" % msg).encode("utf-8", "replace")
	try:
		sys.stderr.buffer.write(line)
		sys.stderr.flush()
	except Exception:
		pass


def get_cache():
	"""Der Eintrag in sys.modules, der Session und Lock zwischen Aufrufen haelt."""
	cache = sys.modules.get(CACHE_NAME)
	if cache is None:
		cache = types.ModuleType(CACHE_NAME)
		cache.lock = threading.Lock()
		cache.session = None
		sys.modules[CACHE_NAME] = cache
	return cache


def get_session():
	"""Die einmal angelegte Streamlink-Session; ImportError ohne Streamlink.

	Rueckgabe: (session, neu angelegt?)"""
	cache = get_cache()
	if cache.session is not None:
		return cache.session, False
	from streamlink import Streamlink
	cache.session = Streamlink()
	return cache.session, True


def resolve_redirect_session(session, url):
	"""stvp-Links ueber die Streamlink-Session aufloesen (wie curl -kLs)."""
	with warnings.catch_warnings():
		# verify=False wie curl -k, ohne InsecureRequestWarning im Log
		warnings.simplefilter("ignore")
		resp = session.http.get(url, stream=True, verify=False, timeout=TIMEOUT)
	try:
		return resp.url.strip()
	finally:
		resp.close()


def resolve_redirect(url):
	"""stvp-Links ohne Streamlink aufloesen (wie curl -kLs -w %{url_effective})."""
	ctx = ssl.create_default_context()
	ctx.check_hostname = False
	ctx.verify_mode = ssl.CERT_NONE
	req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
	with urllib.request.urlopen(req, timeout=TIMEOUT, context=ctx) as resp:
		return resp.geturl().strip()


def stream_url_module(session, url):
	"""Beste Stream-URL ueber die Streamlink-Python-API."""
	streams = session.streams(url)
	for quality in QUALITIES:
		stream = streams.get(quality)
		if stream is None:
			continue
		try:
			return stream.to_url()
		except TypeError:
			# Stream-Typ ohne direkte URL, naechste Qualitaet probieren
			continue
	return ""


def stream_url_cli(url):
	"""Fallback: streamlink-Kommando wie im alten Lua-Script."""
	out = subprocess.run(
		["streamlink", url, ",".join(QUALITIES), "--stream-url"],
		stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
		timeout=TIMEOUT, check=False
	)
	return out.stdout.decode("utf-8", "replace").strip()


def main():
	if len(sys.argv) < 2 or not sys.argv[1]:
		log("Keine URL übergeben")
		return None

	url = sys.argv[1]
	t0 = time.monotonic()

	# Neutrino kann Scripte aus mehreren Threads starten: die gemeinsame
	# Session immer nur von einem Aufruf zur Zeit benutzen
	with get_cache().lock:
		try:
			session, created = get_session()
		except ImportError as e:
			log("Streamlink-Modul nicht importierbar (%s), nehme das Kommando" % e)
			session, created = None, False
		except Exception as e:
			log("Streamlink-Session fehlgeschlagen: %s" % e)
			return None

		final_url = url
		# stvp-Links aufloesen
		if "stvp" in url:
			try:
				if session is not None:
					final_url = resolve_redirect_session(session, url)
				else:
					final_url = resolve_redirect(url)
			except Exception as e:
				log("Weiterleitung fehlgeschlagen: %s" % e)
				return None

		if not final_url:
			return None

		try:
			if session is not None:
				stream_url = stream_url_module(session, final_url)
			else:
				stream_url = stream_url_cli(final_url)
		except Exception as e:
			log("Streamlink-Fehler: %s" % e)
			return None

	log("%s nach %.2f s (Session: %s)" % ("Stream gefunden" if stream_url else "kein Stream",
		time.monotonic() - t0, "neu angelegt" if created else ("wiederverwendet" if session else "keine, streamlink-Kommando")))

	if not stream_url:
		return None

	return json.dumps({"url": stream_url})


result = main()
