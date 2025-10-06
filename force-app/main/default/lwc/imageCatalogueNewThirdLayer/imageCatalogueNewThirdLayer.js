import { LightningElement, api } from 'lwc';
import getActualPicturesApex from '@salesforce/apex/ImageCatalogueController.getActualPictures';

export default class ImageCatalogueNewThirdLayer extends LightningElement {
    allImages = [];
    currentIndex = 0;
    showModal = false;
    _selectedSubCategoryId;

    @api
    set selectedSubCategoryId(value) {
        if (value && value !== this._selectedSubCategoryId) {
            this._selectedSubCategoryId = value;
            this.loadImages(value);
        }
    }
    get selectedSubCategoryId() {
        return this._selectedSubCategoryId;
    }

    async loadImages(recId) {
        try {
            const result = await getActualPicturesApex({ subCategoryId: recId });
            this.allImages = Array.isArray(result) ? result : [];
            this.currentIndex = 0;
        } catch (error) {
            console.error(error);
            this.allImages = [];
            this.currentIndex = 0;
        }
    }

    get hasImages() {
        return Array.isArray(this.allImages) && this.allImages.length > 0;
    }

    get currentImage() {
        return this.hasImages ? this.allImages[this.currentIndex] : null;
    }

    get previousImage() {
        if (!this.hasImages) return null;
        const index = (this.currentIndex - 1 + this.allImages.length) % this.allImages.length;
        return this.allImages[index];
    }

    get nextImage() {
        if (!this.hasImages) return null;
        const index = (this.currentIndex + 1) % this.allImages.length;
        return this.allImages[index];
    }

    absoluteUrl(url) {
        if (!url) return '';
        return url.startsWith('/') ? `${window.location.origin}${url}` : url;
    }

    get currentImageUrl() {
        return this.currentImage?.imageUrls?.[0]
            ? this.absoluteUrl(this.currentImage.imageUrls[0])
            : '';
    }
    get previousImageUrl() {
        return this.previousImage?.imageUrls?.[0]
            ? this.absoluteUrl(this.previousImage.imageUrls[0])
            : '';
    }
    get nextImageUrl() {
        return this.nextImage?.imageUrls?.[0]
            ? this.absoluteUrl(this.nextImage.imageUrls[0])
            : '';
    }

    // Build items for the thumbnail template (no function calls in markup)
    get thumbnailItems() {
        return (this.allImages || []).map((img, index) => {
            const url = img?.imageUrls?.[0] ? this.absoluteUrl(img.imageUrls[0]) : '';
            return {
                key: img?.id ?? String(index),
                index,
                name: img?.name ?? '',
                url,
                className: index === this.currentIndex ? 'active' : ''
            };
        });
    }

    handleThumbnailClick(event) {
        const index = parseInt(event.currentTarget.dataset.index, 10);
        if (!Number.isNaN(index)) {
            this.currentIndex = index;
        }
    }

    handleNext() {
        if (!this.hasImages) return;
        this.currentIndex = (this.currentIndex + 1) % this.allImages.length;
    }

    handlePrevious() {
        if (!this.hasImages) return;
        this.currentIndex = (this.currentIndex - 1 + this.allImages.length) % this.allImages.length;
    }

    handleDownload() {
        const url = this.currentImageUrl;
        if (url) {
            const link = document.createElement('a');
            link.href = url;
            link.download = this.currentImage?.name || 'downloaded-image';
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }
    }

    handleExpand() {
        this.showModal = true;
    }
    handleModalClose() {
        this.showModal = false;
    }
}