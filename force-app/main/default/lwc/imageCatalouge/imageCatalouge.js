import { LightningElement, track, wire } from 'lwc';
import getFilteredProducts from '@salesforce/apex/ProductCatalogController.getFilteredProducts';
import getCategoryOptions from '@salesforce/apex/ProductCatalogController.getCategoryOptions';
import getYearOptions from '@salesforce/apex/ProductCatalogController.getYearOptions';

export default class ImageCatalouge extends LightningElement {
    @track categoryOptions = [];
    @track yearOptions = [];
    selectedCategory = '';
    selectedYear = '';
    searchKey = '';
    @track products = [];
    error;
    imageCredit;

    connectedCallback() {
        this.loadPicklistValues();
    }

    loadPicklistValues() {
        getCategoryOptions()
            .then(result => {
                this.categoryOptions = result.map(item => ({ label: item, value: item }));
            });
        getYearOptions()
            .then(result => {
                this.yearOptions = result.map(item => ({ label: item, value: item }));
            });
    }

    handleCategoryChange(event) {
        this.selectedCategory = event.detail.value;
    }

    handleSelectedYearChange(event) {
        this.selectedYear = event.detail.value;
    }

    handleSearchKeyChange(event) {
        this.searchKey = event.detail.value;
    }
    handleImageCreditsChange( event ){
        this.imageCredit = event.detail.value;
    }
    handleDone() {
        getFilteredProducts({ 
            category: this.selectedCategory, 
            year: this.selectedYear, 
            searchKey: this.searchKey 
        })
            .then(result => {
                this.products = result.map(product => ({
                    id: product.id,
                    name: product.name,
                    category: product.category,
                    year: product.year,
                    imageUrls: product.imageUrls || []
                }));
                console.log("this.products : ", this.product);
                this.error = undefined;
            })
            .catch(error => {
               console.error('Error fetching products', error);
                this.error = error.body ? error.body.message : error.message;
                this.products = [];
            });
    }

}