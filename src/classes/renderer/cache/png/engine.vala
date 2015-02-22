/**
 * PNG cache store
 *
 * This file is part of pdfpc.
 *
 * Copyright (C) 2010-2011 Jakob Westhoff <jakob@westhoffswelt.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
 */

using Cairo;
using Gdk;
using GLib;

using pdfpc;

namespace pdfpc.Renderer.Cache {
    /**
     * Cache store which holds all given items in memory as compressed png
     * images
     */
    public class PNG.Engine: Renderer.Cache.Base {
        /**
         * In memory storage for all the given pixmaps
         */
        protected PNG.Item[] storage = null;

        /**
         * Mutex used to limit access to storage array to one thread at a time.
         *
         * Unfortunately the vala lock statement does not work here.
         */
        protected Mutex mutex = new Mutex();

        /**
         * Initialize the cache store
         */
        public Engine( Metadata.Base metadata ) {
            base( metadata );

            this.mutex.lock();
            this.storage = new PNG.Item[this.metadata.get_slide_count()];
            this.mutex.unlock();
        }

        /**
         * Store a surface in the cache using the given index as identifier
         */
        public override void store( uint index, ImageSurface surface ) {
            int surface_width = surface.get_width();
            int surface_height = surface.get_height();
            int surface_stride = surface.get_stride();

            var item = new PNG.Item( surface.get_data(), surface_width, surface_height, surface_stride );

            this.mutex.lock();
            this.storage[index] = item;
            this.mutex.unlock();
        }

        /**
         * Retrieve a stored surface from the cache.
         *
         * If no item with the given index is available null is returned
         */
        public override ImageSurface? retrieve( uint index ) {
            var item = this.storage[index];
            if ( item == null ) {
                return null;
            }
            var surface = new ImageSurface.for_data( item.get_png_data(), Cairo.Format.RGB24, item.get_width(), item.get_height(), item.get_stride() );

            return surface;
        }
    }
}
