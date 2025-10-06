import { LightningElement, track, wire } from 'lwc';
import getCategory from '@salesforce/apex/ImageCatalogueController.getCategory';
import getSubCategory from '@salesforce/apex/ImageCatalogueController.getSubCategory';
import searchRecords from '@salesforce/apex/ImageCatalogueController.searchRecords';
export default class ImageCatalogueNew extends LightningElement {

    @track categoryOptions = [];
    showThirdLayer = false;
    @track subCategoryOptions = [];
    @track selectedCategoryId;
    @track selectedSubCategoryId;
    searchName = '';
    @track allResults = [];
    @track results = [];
    @track currentPage = 1;
    pageSize = 6;
    totalPages = 6;
    connectedCallback() {
        this.loadCategories();
    }

    loadCategories() {
        getCategory()
            .then(data => {
                this.categoryOptions = data.map(cat => ({ label: cat.name, value: cat.id }));
                console.log("data=====", data);

                this.allResults = data;
                this.setupPagination();

            })
            .catch(error => console.error(error));
    }

    handleCategoryChange(event) {
        this.selectedCategoryId = event.detail.value;
        console.log(this.selectedCategoryId);
        this.subCategoryOptions = [];
        this.selectedSubCategoryId = null;

        if (this.selectedCategoryId) {
            getSubCategory({ categoryId: this.selectedCategoryId })
                .then(data => {
                    this.subCategoryOptions = data.map(sub => ({ label: sub.name, value: sub.id }));
                    this.allResults = data;
                    this.setupPagination();
                })
                .catch(error => console.error(error));
        }
    }

    handleSubCategoryChange(event) {
        this.selectedSubCategoryId = event.detail.value;

        if (this.selectedSubCategoryId) {
            this.showThirdLayer = true;
            this.template.querySelector('c-image-catalogue-new-third-layer').getselectedSubCategoryId(this.selectedSubCategoryId);
            this.totalPages = 1;
            this.currentPage = 1;
        } else {
            this.setupPagination();
        }
    }

    handleSearchChange(event) {
        this.searchName = event.target.value;

        if (this.searchName) {
            searchRecords({ searchName: this.searchName })
                .then(data => {
                    this.allResults = data;
                    this.setupPagination();
                })
                .catch(error => console.error(error));
        } else {

            this.loadCategories();
        }
    }



    handleClear() {
        this.selectedCategoryId = '';
        this.selectedSubCategoryId = '';
        this.searchName = '';
        this.subCategoryOptions = [];
        this.allResults = [];
        this.results = [];
        this.currentPage = 1;
        this.totalPages = 0;
        this.loadCategories();
        this.showThirdLayer = false;
    }


    setupPagination() {
        this.totalPages = Math.ceil(this.allResults.length / this.pageSize);
        this.currentPage = 1;
        this.updatePageResults();
    }

    updatePageResults() {
        const start = (this.currentPage - 1) * this.pageSize;
        const end = this.currentPage * this.pageSize;
        this.results = this.allResults.slice(start, end);
    }

    handlePrev() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.updatePageResults();
        }
    }

    handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.updatePageResults();
        }
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages || this.totalPages === 0;
    }

    handleImageClick(event) {
        const recId = event.currentTarget.dataset.id;

        const categoryMatch = this.categoryOptions.find(cat => cat.value === recId);
        if (categoryMatch) {
            this.selectedCategoryId = recId;
            getSubCategory({ categoryId: this.selectedCategoryId })
                .then(data => {
                    this.subCategoryOptions = data.map(sub => ({ label: sub.name, value: sub.id }));
                    this.allResults = data;
                    this.setupPagination();
                })
                .catch(error => console.error(error));
            return;
        }

        const subCatMatch = this.subCategoryOptions.find(sub => sub.value === recId);
        if (subCatMatch) {
            this.selectedSubCategoryId = recId;
            console.log('subCatMatch image click run', this.selectedSubCategoryId);
            this.showThirdLayer = true;
            this.results = this.allResults.filter(rec => rec.id === recId);
            this.totalPages = 1;
            this.currentPage = 1;
        }
    }

}